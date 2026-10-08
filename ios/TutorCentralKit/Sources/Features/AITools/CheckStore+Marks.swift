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
            let updated = try await students.updateNotes(id: student.id, notes: notes)
            notesNow[student.id] = updated.notes
            previousNotes = current
            saved = true
            toast = StudentNoteLine.toast(studentFirstName: student.firstName, title: title, result: result)
            onStudentChanged?()
            return true
        } catch {
            message = "Couldn't save to \(student.firstName)'s notes. Check your connection and try again."
            return false
        }
    }

    /// The toast's Undo: the notes exactly as they were (nil stays nil).
    func undoSave() async -> Bool {
        guard let student, saved else { return false }
        do {
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
