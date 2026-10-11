import Data
import Domain
import Foundation

public extension ReadMarksStore {
    /// The row's sheet saved: a date set ticks the row.
    func edit(_ id: UUID, _ mark: ReadMark) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let dated = rows[index].mark.date == nil && mark.date != nil
        rows[index].mark = mark
        if dated {
            rows[index].ticked = true
        }
        if mark.date == nil {
            rows[index].ticked = false
        }
    }

    /// The row's tick; a row without a date cannot be ticked.
    func toggle(_ id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows[index].mark.date != nil else { return }
        rows[index].ticked.toggle()
    }

    /// Remove this mark (the sheet).
    func remove(_ id: UUID) {
        rows.removeAll { $0.id == id }
    }

    /// A mark per ticked row; refused offline with the rows kept. A failure part way takes back what was written.
    func save() async -> Bool {
        guard canSave, let student else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .saveMarks)
            return false
        }
        stage = .saving
        var written: [UUID] = []
        do {
            for row in ticked {
                guard let date = row.mark.date else { continue }
                let mark = try await record.addMark(
                    NewMark(
                        studentID: student.id, subject: row.mark.subject, test: row.mark.test, date: date,
                        score: row.mark.score, max: row.mark.max
                    ),
                    centre: centre
                )
                written.append(mark.id)
            }
        } catch {
            for id in written {
                try? await record.deleteMark(id: id, centre: centre)
            }
            stage = .read
            message = "The marks weren't saved. Check your connection and try again."
            return false
        }
        saved = written
        let count = written.count == 1 ? "1 mark" : "\(written.count) marks"
        toast = "\(count) saved to \(student.firstName)'s page"
        stage = .read
        return true
    }

    /// The toast's Undo: each mark saved taken back; nil when done, else the words for the alert (the screen has gone,
    /// so they are returned, not set). A mark not yet taken back stays for another Undo.
    func undo() async -> String? {
        while let id = saved.first {
            do {
                try await record.deleteMark(id: id, centre: centre)
            } catch {
                return Self.undoFailed
            }
            saved.removeFirst()
        }
        toast = nil
        return nil
    }
}
