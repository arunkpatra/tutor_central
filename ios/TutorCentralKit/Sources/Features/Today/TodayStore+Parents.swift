import Data
import Domain
import Foundation

/// One message that goes now after the close: Test tomorrow for a student whose exam is tomorrow, Absent today for a
/// student marked absent (P10-Today-AfterClose; plan/phase-13-plan.md decision 21).
public struct ParentRowModel: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case testTomorrow(SchoolItem)
        case absentToday
    }

    public enum State: Hashable, Sendable { case send, sent }

    public var id: String {
        switch kind {
        case let .testTomorrow(item): "test-\(item.id)-\(studentID)"
        case .absentToday: "absent-\(studentID)"
        }
    }

    public let kind: Kind
    public let studentID: UUID
    public let initials: String
    /// "Test tomorrow", "Absent today".
    public let title: String
    /// "Dev's parent · Hindi · Science unit test on Thu 8 Oct, chapters 1 and 2".
    public let detail: String
    public let state: State
}

extension TodayStore {
    /// After a batch closed today: Test tomorrow for its students with an exam tomorrow (unless the parent's three
    /// suggested messages this week are spent), Absent today for those marked absent; each Sent once logged today.
    func loadParents() async {
        let closedToday = sessions.filter { $0.date == today && $0.closedAt != nil }
        guard !closedToday.isEmpty, let messages else {
            toParents = []
            return
        }
        let centre = workspace.centre.id
        let monday = today.adding(days: 1 - today.weekday(in: calendar).rawValue, calendar: calendar)
        async let itemsRead = try? schoolItems?.items(centre: centre)
        async let logRead = try? messages.entries(centre: centre, since: monday.date(in: calendar))
        let items = await itemsRead ?? []
        let log = await logRead ?? []
        let tomorrow = today.adding(days: 1, calendar: calendar)
        let startOfToday = today.date(in: calendar)
        var rows: [ParentRowModel] = []
        for session in closedToday {
            let present = session.marks.filter { $0.value != .absent }.keys
            for student in register.activeStudents.filter({ present.contains($0.id) })
                .sorted(by: { $0.name < $1.name }) {
                guard student.parentPhone != nil,
                      let exam = items.filter({ $0.kind == .exam && $0.date == tomorrow && SchoolItemRules.reaches(
                          $0,
                          student
                      ) })
                      .min(by: { $0.title < $1.title }) else { continue }
                let theirs = log.filter { sameParent($0.studentID, student) }.map(\.entry)
                let sent = log.contains {
                    $0.studentID == student.id && $0.entry.kind == .testTomorrow && $0.entry.openedAt >= startOfToday
                }
                guard sent || MessageCadence.canSuggest(theirs, now: clock, calendar: calendar) else { continue }
                let what = [exam.title + " on " + exam.date.shortWeekdayText, exam.portions].compactMap(\.self)
                    .joined(separator: ", ")
                rows.append(row(.testTomorrow(exam), student, title: "Test tomorrow", what: what, sent: sent))
            }
            let absent = session.marks.filter { $0.value == .absent }.keys
            for student in register.activeStudents.filter({ absent.contains($0.id) && $0.parentPhone != nil })
                .sorted(by: { $0.name < $1.name }) {
                let sent = log.contains {
                    $0.studentID == student.id && $0.entry.kind == .absence && $0.entry.openedAt >= startOfToday
                }
                rows.append(row(.absentToday, student, title: "Absent today", what: "the absence alert", sent: sent))
            }
        }
        toParents = rows
    }

    private func row(
        _ kind: ParentRowModel.Kind, _ student: Student, title: String, what: String, sent: Bool
    ) -> ParentRowModel {
        ParentRowModel(
            kind: kind, studentID: student.id, initials: student.initials, title: title,
            detail: "\(student.firstName)'s parent · \(student.messageLanguage.title) · \(what)",
            state: sent ? .sent : .send
        )
    }

    /// A message about another student of the same parent (the same number).
    private func sameParent(_ id: UUID, _ student: Student) -> Bool {
        guard let number = student.parentPhone?.e164 else { return id == student.id }
        return id == student.id || register.student(id)?.parentPhone?.e164 == number
    }
}
