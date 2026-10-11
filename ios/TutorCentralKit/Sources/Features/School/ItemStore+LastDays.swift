import Data
import DesignSystem
import Domain
import Foundation

/// A student of the exam in the last days' Marked (P10-School-Exam-LastDays): the score and the weakest skill, or "Not
/// marked yet"; the gap report when made; whether the student can be marked and reported (their parent's consent).
public struct MarkedRow: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let initials: String
    public let name: String
    /// "14 of 25 · Balancing equations 3 of 10", "21 of 25 · all skills secure", "Not marked yet".
    public let line: String
    public let gapReportID: UUID?
    /// Marked and the parent agreed: Gap report shows.
    public let canReport: Bool
    public let canMark: Bool
    /// "Marking waits for Arup's consent".
    public let consentLine: String?
}

/// The exam's last days (P10-School-Exam-LastDays): Today with the mock, Marked, The last two days.
public struct LastDaysModel: Hashable, Sendable {
    public enum MockState: Hashable, Sendable { case ready, notMade }

    /// "Today, Wednesday".
    public let todayTitle: String
    /// "The mock, for Dev, Meher and Nikhil".
    public let mockTitle: String
    /// "In the school's pattern · 40 marks · 60 minutes"; before it is made, "The mock is made with Wednesday's plan".
    public let mockLine: String
    public let mockState: MockState
    public let mock: Artefact?
    public let marked: [MarkedRow]
    /// The days after the mock and the test.
    public let lastDays: [PreparationRowModel]

    public var mockID: UUID? {
        mock?.id
    }

    public static let markLine = "Each paper photographed after the class; the marks are suggested, you decide"
}

extension ItemStore {
    func lastDaysModel(
        _ item: SchoolItem, split: [PreparationDay], students: [Student], mock: Artefact?
    ) async -> LastDaysModel {
        let centre = workspace.centre.id
        let byName = students.sorted { $0.name < $1.name }
        async let marksRead = try? record?.marks(centre: centre, students: byName.map(\.id))
        async let keptRead = try? plans?.artefacts(for: item.id, centre: centre)
        let marks = await (marksRead ?? []).filter { $0.schoolItemID == item.id }
        let reports = await (keptRead ?? []).filter { $0.kind == .gapReport }
        var content: MockContent?
        if case let .mock(made)? = mock?.content {
            content = made
        }
        let weekday = { (day: Day) in day.weekdayLongText.split(separator: " ").first.map(String.init) ?? "" }
        let mockDay = split.first { $0.kind == .mock }?.day ?? today
        let level = byName.compactMap(\.classLevel).max()
        let pattern = content?.pattern ?? MockPattern.default(for: level)
        let rows = byName.map { student in
            markedRow(
                student, mark: marks.filter { $0.studentID == student.id }.max { $0.date < $1.date },
                mock: content, report: reports.first { $0.studentID == student.id }
            )
        }
        return LastDaysModel(
            todayTitle: "Today, \(weekday(today))",
            mockTitle: "The mock, for \(ListWordsBridge.and(byName.map(\.firstName)))",
            mockLine: mock == nil ? "The mock is made with \(weekday(mockDay))'s plan"
                : "In the school's pattern · \(pattern.line)",
            mockState: mock == nil ? .notMade : .ready, mock: mock, marked: rows,
            lastDays: lastDayRows(item, split: split, students: byName, reports: reports)
        )
    }

    private func markedRow(_ student: Student, mark: MarkRecord?, mock: MockContent?, report: Artefact?) -> MarkedRow {
        let agreed = student.consent != nil
        var line = "Not marked yet"
        if let mark {
            line = "\(mark.score) of \(mark.max)"
            if let mock {
                let tallies = GapTallies.bySkill(CheckResult(questions: mark.questions ?? [], summary: ""), mock: mock)
                if let weakest = GapTallies.weakest(tallies, count: 1).first,
                   let tally = tallies.first(where: { $0.skill == weakest }) {
                    line += " · \(weakest) \(tally.right) of \(tally.of)"
                } else {
                    line += " · all skills secure"
                }
            }
        }
        let parent = student.parentName?.split(separator: " ").first.map { "\($0)'s" } ?? "their parent's"
        return MarkedRow(
            id: student.id, initials: student.initials, name: student.name, line: line, gapReportID: report?.id,
            canReport: agreed && mark != nil, canMark: agreed,
            consentLine: agreed ? nil : "Marking waits for \(parent) consent"
        )
    }

    /// The days after the mock ("What the mocks showed": each used report's line for the day, by student) and the test.
    private func lastDayRows(
        _ item: SchoolItem, split: [PreparationDay], students: [Student], reports: [Artefact]
    ) -> [PreparationRowModel] {
        let after = split.filter { $0.kind == .afterMock && $0.day >= today }
        let rows = after.enumerated().map { index, day -> PreparationRowModel in
            let lines = students.compactMap { student -> String? in
                guard let report = reports.first(where: { $0.studentID == student.id }),
                      case let .gapReport(content) = report.content, content.usedAt != nil,
                      index < content.days.count else { return nil }
                let line = content.days[index].line
                return "\(student.firstName): \(line.prefix(1).lowercased())\(line.dropFirst())"
            }
            return lastRow(
                day.day,
                title: "What the mocks showed",
                line: lines.isEmpty ? "The last set from the gap report" : lines.joined(separator: " · ")
            )
        }
        return rows + [lastRow(item.date, title: "The test", line: "")]
    }

    private func lastRow(_ day: Day, title: String, line: String) -> PreparationRowModel {
        PreparationRowModel(
            id: day, day: day.weekdayDayText.split(separator: " ").first.map(String.init) ?? "", date: day.shortText,
            title: title, line: line, mark: .none, opens: nil
        )
    }
}
