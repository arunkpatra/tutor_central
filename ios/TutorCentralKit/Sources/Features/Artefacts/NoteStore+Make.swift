import Data
import Domain
import Foundation

extension NoteStore {
    /// The note kept this week: the copy on this iPhone at once (U47: a connection that hangs takes 20 s to give up),
    /// then the plans' (the newer when both), else a new one made.
    public func load() async {
        // A link or a launch state can open the note before the register is read.
        await context.register.loadIfNeeded()
        guard let student else {
            stage = .failed("This student is no longer here.")
            return
        }
        let copy = copiedNote()
        if let copy {
            show(copy)
        }
        let served = await servedNote()
        guard !Task.isCancelled else { return }
        if let found = served ?? copy, tutorSays != nil {
            show(found)
            await make(student: student, from: found.id)
            return
        }
        if let found = served ?? copy {
            if found.kind == .canDo, let record = try? await context.reader.read(
                [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
                calendar: context.calendar
            )[student.id] {
                // "Moved up" is drawn from the ladder; the kept note's own facts stand.
                prepareFacts(record)
            }
            show(found)
            return
        }
        await make(student: student, from: nil)
    }

    /// Try Again after a failed call.
    public func make() async {
        guard let student else { return }
        await make(student: student, from: kept?.id)
    }

    /// A fresh draft, a new call though the facts are the same; the shown one stays kept (`regenerated_from`).
    public func writeAgain() async {
        guard let student else { return }
        await IdempotencyKey.another { await make(student: student, from: kept?.id) }
    }

    /// Copy: the signed note on the pasteboard, logged as copied when a connection allows; nothing is sent.
    public func copy() async {
        let body = signedBody
        effects.copy(body)
        guard await context.online() else { return }
        _ = try? await context.messages.logMessage(
            ParentMessage(studentID: studentID, kind: kind, language: language, body: body, channel: .copied),
            centre: context.workspace.centre.id
        )
    }

    /// The two-language sheet's Open WhatsApp: the kind, the language and the signed words logged, then copied and the
    /// link opened (D3). Nothing is logged over the limit or offline.
    public func send() async -> Bool {
        guard canSend, let phone = student?.parentPhone else { return false }
        guard await context.online() else {
            alert = OfflineRefusal.words(for: .sendNote)
            return false
        }
        let body = signedBody
        do {
            _ = try await context.messages.logMessage(
                ParentMessage(studentID: studentID, kind: kind, language: language, body: body, channel: .whatsAppLink),
                centre: context.workspace.centre.id
            )
        } catch {
            alert = "That didn't go through. Check your connection and try again."
            return false
        }
        effects.copy(body)
        sent = true
        effects.open(AbsenceMessage.whatsAppURL(phone: phone, text: body))
        return true
    }

    var kind: MessageKind {
        isLadder ? .canDo : .note
    }

    private func ofThisWeek(_ artefact: Artefact) -> Bool {
        guard artefact.studentID == studentID, case let .note(content) = artefact.content else { return false }
        return content.weekMonday == week.lowerBound
    }

    /// This week's note in the copy on this iPhone.
    private func copiedNote() -> Artefact? {
        context.notesCache?.read().sorted { $0.madeAt > $1.madeAt }.first(where: ofThisWeek)
    }

    /// This week's note in the plans; nil offline or when the read fails.
    private func servedNote() async -> Artefact? {
        guard await context.online() else { return nil }
        let since = week.lowerBound.date(in: context.calendar)
        let read = try? await context.plans.notes(
            centre: context.workspace.centre.id,
            students: [studentID],
            since: since
        )
        return read?.first(where: ofThisWeek)
    }

    private func show(_ artefact: Artefact) {
        guard case let .note(content) = artefact.content else { return }
        kept = artefact
        self.content = content
        isLadder = artefact.kind == .canDo
        message = content.message
        english = content.english
        facts = content.facts
        stage = .ready
    }

    private func make(student: Student, from previous: UUID?) async {
        let records = try? await context.reader.read(
            [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
            calendar: context.calendar
        )
        let record = records?[student.id]
        if let record {
            prepareFacts(record)
        }
        guard student.consent != nil else {
            stage = .failed(NoteConsent.waiting(student))
            return
        }
        guard await context.online() else {
            stage = .failed(OfflineRefusal.words(for: .weeklyNote))
            return
        }
        guard let record else {
            stage = .failed("Couldn't read this week's record. Check your connection and try again.")
            return
        }
        stage = .writing
        canRetry = false
        let words = isLadder ? nil : tutorSays ?? content?.tutorSays
        do {
            let made = try await call(record, student: student, saying: words)
            let note = NoteContent(
                message: made.message, english: language == .english ? nil : made.english, language: language,
                weekMonday: week.lowerBound, facts: facts, generationID: made.generationID, tutorSays: words
            )
            let title = isLadder ? "\(student.firstName) can now do" : "\(student.firstName)'s week"
            let new = NewNote(
                studentID: student.id, kind: isLadder ? .canDo : .note, title: title, content: note,
                regeneratedFrom: previous
            )
            // The call is paid for: the note is kept even when the screen was left meanwhile (a task of its own, not
            // cancelled with the screen's), so the next Read opens it rather than paying again.
            let plans = context.plans
            let centre = context.workspace.centre.id
            let artefact = try await Task { try await plans.keepNote(new, centre: centre) }.value
            keepCopy(artefact)
            show(artefact)
        } catch let failure as APIFailure {
            canRetry = true
            stage = .failed(failure.message)
        } catch {
            canRetry = true
            stage = .failed("That didn't go through. Check your connection and try again.")
        }
    }

    private func call(
        _ record: NoteRecord, student: Student, saying words: String?
    ) async throws(APIFailure) -> MadeMessage {
        let workspace = context.workspace
        let tutor = workspace.profile.displayName ?? workspace.centre.name
        let level = student.classLevel ?? .messageFallback
        if isLadder {
            let facts = CanDoWeek.facts(
                chapters: record.chapters, skills: record.skills, week: week, calendar: context.calendar
            )
            return try await context.ai.makeCanDo(
                CanDoRequest(
                    studentID: student.id, studentName: student.name, parentName: student.parentName, tutorName: tutor,
                    centreName: workspace.centre.name, classLevel: level, language: language, facts: facts
                ),
                centre: workspace.centre.id
            )
        }
        let facts = NoteWeek.facts(record, week: week, calendar: context.calendar)
        let request = NoteRequest(
            studentID: student.id, studentName: student.name, parentName: student.parentName, tutorName: tutor,
            centreName: workspace.centre.name, classLevel: level, language: language, weekMonday: week.lowerBound,
            week: NoteRequest.Week(facts)
        )
        return try await context.ai.makeNote(words.map(request.saying) ?? request, centre: workspace.centre.id)
    }

    /// The facts the screen shows while the note is written, and "Moved up" for the ladder.
    private func prepareFacts(_ record: NoteRecord) {
        isLadder = CanDoWeek.isLadderNote(record.student, chapters: record.chapters)
        guard isLadder else {
            facts = NoteWeek.facts(record, week: week, calendar: context.calendar).rows
            ladder = nil
            return
        }
        let can = CanDoWeek.facts(
            chapters: record.chapters,
            skills: record.skills,
            week: week,
            calendar: context.calendar
        )
        facts = can.rows
        let area = can.movedUp.first?.area ?? .reading
        let step = can.movedUp.first.flatMap { area.steps.firstIndex(of: $0.step) }
            ?? ladderStep(area, record: record)
        ladder = LadderModel(
            heading: can.ladderHeading, area: area.title, steps: area.steps, current: step, line: can.movedUpLine
        )
    }

    /// The highest secure step of an area, the first when none is.
    private func ladderStep(_ area: Ladder.Area, record: NoteRecord) -> Int {
        guard let chapter = record.chapters.first(where: { $0.ladder == area }) else { return 0 }
        let states = record.skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
            .map(\.state)
        return max(0, (Ladder.currentStep(states) ?? states.count) - 1)
    }

    private func keepCopy(_ artefact: Artefact) {
        guard let cache = context.notesCache else { return }
        let since = week.lowerBound.date(in: context.calendar)
        let others = cache.read().filter { $0.id != artefact.id && $0.madeAt >= since.addingTimeInterval(-7 * 86400) }
        try? cache.keep([artefact] + others)
    }
}
