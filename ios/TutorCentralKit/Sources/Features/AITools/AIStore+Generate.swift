import Data
import Domain
import Foundation

/// Create, Create again, Cancel, Retry and the note's Send: one call at a time, owned by the store.
public extension AIStore {
    /// Refused in words while one runs; the consent sheet first for a note without consent.
    func create(_ request: GenerateRequest) -> CreateOutcome {
        start(request, regenerating: nil)
    }

    /// The same input again; the old result stays until the new one lands.
    func createAgain(_ generation: Generation) -> CreateOutcome {
        guard let request = generation.request else { return .invalid }
        return start(request, regenerating: generation.id)
    }

    /// Stops waiting. The row stays pending on the server and counts against the day (the safe side).
    func cancel() {
        task?.cancel()
        task = nil
        inFlight = nil
    }

    func retry() {
        guard let last = lastRequest else { return }
        _ = start(last.request, regenerating: last.regenerating)
    }

    /// The names the API needs: the class (or the student's), the subject, the student and parent, the month's line,
    /// the tutor and the centre.
    func context(for request: GenerateRequest) -> GenerateContext {
        let student: Student? = if case let .progressNote(form) = request {
            form.studentID.flatMap(register.student)
        } else {
            nil
        }
        let classroom = register.classroom(request.classID ?? student?.classID)
        let typedSubject: String? = switch request {
        case let .paper(form): form.subject
        case let .homework(form): form.subject
        case let .worksheet(form): form.subject
        case .progressNote: nil
        }
        let subject = typedSubject?.trimmingCharacters(in: .whitespacesAndNewlines) ?? classroom?.subject
            ?? classroom?.name ?? "General"
        return GenerateContext(
            centre: workspace.centre.id, className: classroom?.name, subject: subject.isEmpty ? "General" : subject,
            studentName: student?.name, parentName: student?.parentName,
            attendanceLine: student.flatMap { monthLines[$0.id] }, tutorName: workspace.profile.displayName ?? "",
            centreName: workspace.centre.name
        )
    }

    /// The Send the note sheet: the student, the parent and their number, the note with the signature, the link.
    func noteMessage(_ generation: Generation, text: String) -> NoteMessage? {
        guard let student = generation.studentID.flatMap(register.student) else { return nil }
        let signature = [workspace.profile.displayName, workspace.centre.name].compactMap(\.self)
            .joined(separator: "\n")
        let full = "\(text.trimmingCharacters(in: .whitespacesAndNewlines))\n\n\(signature)"
        let parent = [student.parentName, student.parentPhone?.display].compactMap(\.self).joined(separator: " · ")
        return NoteMessage(
            studentID: student.id, name: student.name, firstName: student.firstName, parentLine: parent, text: full,
            url: student.parentPhone.map { AbsenceMessage.whatsAppURL(phone: $0, text: full) }
        )
    }

    /// Open WhatsApp: the `progress` row first (D3), then the text copied and the link opened.
    func openNote(_ generation: Generation, text: String) async {
        guard let note = noteMessage(generation, text: text) else { return }
        do {
            _ = try await messages(note)
        } catch {
            message = "Couldn't note it on the student's page. Check your connection and try again."
            return
        }
        effects.copy(note.text)
        if let url = note.url {
            await effects.open(url)
        }
    }

    private func messages(_ note: NoteMessage) async throws -> Date {
        try await messagesRepository.logProgress(centre: workspace.centre.id, studentID: note.studentID)
    }

    private func noteStudent(_ request: GenerateRequest) -> Student? {
        guard case let .progressNote(form) = request else { return nil }
        return form.studentID.flatMap(register.student)
    }

    private func start(_ request: GenerateRequest, regenerating: UUID?) -> CreateOutcome {
        guard request.isValid else { return .invalid }
        guard inFlight == nil else {
            message = "One at a time: the last one is still being written."
            return .busy
        }
        if request.kind.needsConsent, needsConsent {
            return .needsConsent
        }
        if regenerating == nil {
            forms[request.kind] = request
        }
        failure = nil
        lastRequest = (request, regenerating)
        let first = { (form: NoteForm) in form.studentID.flatMap(self.register.student)?.firstName }
        let studentFirst: String? = if case let .progressNote(form) = request {
            first(form)
        } else {
            nil
        }
        inFlight = InFlight(
            kind: request.kind, request: request, regenerating: regenerating,
            line: request.creatingLine(studentFirstName: studentFirst)
        )
        let context = context(for: request)
        task = Task { [weak self] in
            await self?.run(request, context: context)
        }
        return .started
    }

    private func run(_ request: GenerateRequest, context: GenerateContext) async {
        do {
            let generation = try await ai.generate(request, context: context)
            guard !Task.isCancelled else { return }
            results[generation.id] = generation
            history.insert(generation, at: 0)
            lastReplaced = inFlight?.regenerating
            inFlight = nil
            task = nil
            onResult?(generation)
        } catch {
            guard !Task.isCancelled else { return }
            inFlight = nil
            task = nil
            let canRetry = if case .limit = error {
                false
            } else {
                true
            }
            failure = Failure(
                kind: request.kind,
                message: error.message,
                consent: error == .consent,
                canRetry: canRetry
            )
            if error == .consent {
                workspace.centre.aiConsentAt = nil
            }
        }
    }
}

/// The Send the note sheet's content (P6-ProgressNote-Send).
public struct NoteMessage: Hashable, Sendable {
    public let studentID: UUID
    public let name: String
    public let firstName: String
    public let parentLine: String
    /// The note as edited, a blank line, then the tutor's name and the centre's.
    public let text: String
    /// Nil without the parent's number: the sheet says so and Open WhatsApp is disabled.
    public let url: URL?
}
