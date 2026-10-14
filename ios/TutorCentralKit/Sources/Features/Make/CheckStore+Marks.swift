import Data
import Domain
import Foundation

/// The marks, Save and its Undo, and the words the result screen shows.
public extension CheckStore {
    func set(question: Int, to marks: Int) {
        guard let result else { return }
        self.result = MarkEdit.set(result, question: question, to: marks)
    }

    var saveLabel: String {
        guard let result, let student else { return "Save to the student's notes" }
        return MarkEdit.saveLabel(result, studentFirstName: student.firstName)
    }

    /// "10 questions · 2 pages · checked today".
    var totalLine: String {
        guard let result else { return "" }
        let questions = result.questions.count == 1 ? "1 question" : "\(result.questions.count) questions"
        let pageCount = pages.count == 1 ? "1 page" : "\(pages.count) pages"
        return "\(questions) · \(pageCount) · checked today"
    }

    /// The marks as plain text for Share: the title and student, a line per question, the total.
    var shareText: String {
        guard let result else { return "" }
        let lines = result.questions.map { "Q\($0.number) · \($0.marks) of \($0.of) · \($0.note)" }
        let head = [title, student?.name].compactMap(\.self).joined(separator: " · ")
        return ([head] + lines + ["Total \(result.total) of \(result.outOf)", result.summary]).joined(separator: "\n")
    }

    /// One line on the end of the student's notes; refused in words when the notes would be over their limit.
    func save() async -> Bool {
        guard let result, let student, !saving else { return false }
        let current = notesNow[student.id] ?? student.notes
        let line = StudentNoteLine.make(day: Day(now(), calendar: calendar), title: title, result: result)
        guard let notes = NotesAppend.append(line, to: current) else {
            message = NotesAppend.overflow(studentFirstName: student.firstName)
            return false
        }
        saving = true
        defer { saving = false }
        do {
            savedMarkID = try await writeMark(result, student: student)
        } catch {
            message = "Couldn't save \(student.firstName)'s marks. Check your connection and try again."
            return false
        }
        do {
            let updated = try await students.updateNotes(id: student.id, notes: notes)
            notesNow[student.id] = updated.notes
            previousNotes = current
            saved = true
            toast = StudentNoteLine.toast(studentFirstName: student.firstName, title: title, result: result)
            await wakeExamJob()
            onStudentChanged?()
            return true
        } catch {
            await removeMark()
            message = "Couldn't save to \(student.firstName)'s notes. Check your connection and try again."
            return false
        }
    }

    /// An exam's marks wake its job (D106) for the student's gap report; without the wake the job finds them at its
    /// next look, within 15 minutes.
    private func wakeExamJob() async {
        guard savedMarkID != nil, let item = markTarget?.schoolItemID, let jobs else { return }
        _ = try? await jobs.requestExamPrep(centre: workspace.centre.id, item: item)
    }

    /// The mark of a mock's check (the preset's target) or of a paper made here (its subject and title); a typed
    /// scheme writes none.
    internal func writeMark(_ result: CheckResult, student: Student) async throws -> UUID? {
        guard let record, let target = markTarget else { return nil }
        let mark = NewMark(
            studentID: student.id, subject: target.subject, test: target.test, date: Day(now(), calendar: calendar),
            score: result.total, max: result.outOf, schoolItemID: target.schoolItemID, artefactID: target.artefactID,
            questions: result.questions
        )
        return try await record.addMark(mark, centre: workspace.centre.id).id
    }

    internal func removeMark() async {
        guard let id = savedMarkID else { return }
        try? await record?.deleteMark(id: id, centre: workspace.centre.id)
        savedMarkID = nil
    }

    internal var markTarget: MarkTarget? {
        if let mark = presetInUse?.mark ?? chosenMark {
            return mark
        }
        guard case let .paper(id) = scheme, let paper = papers.first(where: { $0.id == id }),
              let subject = paper.request?.subject, !subject.isEmpty else { return nil }
        return MarkTarget(subject: subject, test: title, schoolItemID: nil, artefactID: nil)
    }

    /// The toast's Undo: the notes exactly as they were (nil stays nil).
    func undoSave() async -> Bool {
        guard let student, saved else { return false }
        do {
            if let id = savedMarkID {
                try await record?.deleteMark(id: id, centre: workspace.centre.id)
                savedMarkID = nil
            }
            _ = try await students.updateNotes(id: student.id, notes: previousNotes)
            notesNow[student.id] = previousNotes
            saved = false
            toast = nil
            onStudentChanged?()
            return true
        } catch {
            message = "Couldn't undo. Check your connection and try again."
            return false
        }
    }
}

private extension GenerateRequest {
    /// The subject a paper, homework or worksheet was made for; a progress note has none.
    var subject: String? {
        switch self {
        case let .paper(form): form.subject
        case let .homework(form): form.subject
        case let .worksheet(form): form.subject
        case .progressNote: nil
        }
    }
}
