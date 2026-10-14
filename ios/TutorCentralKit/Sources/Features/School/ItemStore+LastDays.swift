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
    /// Marked, and the exam's job is working out the gap report (P21-Exam-GapWorking).
    public let working: Bool
    /// Marked and the parent agreed: Gap report shows.
    public let canReport: Bool
    public let canMark: Bool
    /// "Marking waits for Arup's consent".
    public let consentLine: String?
}

/// The exam's last days (P10-School-Exam-LastDays): Today with the mock, Marked, The last two days.
public struct LastDaysModel: Hashable, Sendable {
    /// `making`: the exam's job makes it this morning (P21-Exam-MockMaking); `failed`: it could not
    /// (P21-Exam-MockFailed).
    public enum MockState: Hashable, Sendable { case ready, notMade, making, failed }

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
    /// Mark from a photo while the mock is not ready (P21-Exam-MockMaking, -MockFailed).
    public static let markWaitsLine = "Once the mock is ready"
    public static let mockFailedLine = "Couldn't make the mock. Try again, or set a paper of your own."

    /// Any of the last days changed by a gap report: the section's Change.
    public var changed: Bool {
        lastDays.contains(where: \.changed)
    }
}

extension ItemStore {
    func lastDaysModel(
        _ item: SchoolItem, split: [PreparationDay], students: [Student], mock: Artefact?
    ) async -> LastDaysModel {
        let centre = workspace.centre.id
        let byName = students.sorted { $0.name < $1.name }
        async let marksRead = try? record?.marks(centre: centre, students: byName.map(\.id))
        async let keptRead = try? plans?.artefacts(for: item.id, centre: centre)
        async let jobRead = try? jobs?.examJob(centre: centre, item: item.id)
        let marks = await (marksRead ?? []).filter { $0.schoolItemID == item.id }
        let reports = await (keptRead ?? []).filter { $0.kind == .gapReport }
        let job = await jobRead ?? nil
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
                mock: content, report: reports.first { $0.studentID == student.id }, jobWorks: job?.isLive == true
            )
        }
        let state = Self.mockState(mock: mock, job: job, today: today, mockDay: mockDay)
        let mockLine = switch state {
        case .ready: "In the school's pattern · \(pattern.line)"
        case .making: "In the school's pattern · \(pattern.marks) marks · usually ready in a minute"
        case .failed: LastDaysModel.mockFailedLine
        case .notMade: "The mock is made with \(weekday(mockDay))'s plan"
        }
        return LastDaysModel(
            todayTitle: "Today, \(weekday(today))",
            mockTitle: "The mock, for \(ListWordsBridge.and(byName.map(\.firstName)))",
            mockLine: mockLine, mockState: state, mock: mock, marked: rows,
            lastDays: lastDayRows(
                item, split: split, students: byName, reports: reports,
                pending: Self.pendingWords(byName, reports: reports, marks: marks, jobWorks: job?.isLive == true)
            )
        )
    }

    /// The mock's row by the exam's job (D106): made; not made by the job; being made from its morning while the job is
    /// live; otherwise made with the mock day's plan.
    public nonisolated static func mockState(
        mock: Artefact?,
        job: ExamJobStatus?,
        today: Day,
        mockDay: Day
    ) -> LastDaysModel
        .MockState {
        if mock != nil {
            return .ready
        }
        if let job, job.mockFailed {
            return .failed
        }
        if let job, job.isLive, today >= mockDay {
            return .making
        }
        return .notMade
    }

    private func markedRow(
        _ student: Student, mark: MarkRecord?, mock: MockContent?, report: Artefact?, jobWorks: Bool
    ) -> MarkedRow {
        let agreed = student.consent != nil
        var line = "Not marked yet"
        // Marked with no report yet while the exam's job runs: it is working the report out (P21-Exam-GapWorking).
        let working = mark != nil && report == nil && jobWorks && agreed
        var used = false
        if case let .gapReport(content)? = report?.content {
            used = content.usedAt != nil
        }
        if let mark, working {
            line = "\(mark.score) of \(mark.max) · working out the last two days"
        } else if let mark {
            line = "\(mark.score) of \(mark.max)"
            if let mock {
                let tallies = GapTallies.bySkill(CheckResult(questions: mark.questions ?? [], summary: ""), mock: mock)
                if let weakest = GapTallies.weakest(tallies, count: 1).first,
                   let tally = tallies.first(where: { $0.skill == weakest }) {
                    line += " · \(weakest) \(tally.right) of \(tally.of)"
                    if used {
                        line += " · the last two days changed"
                    }
                } else {
                    line += " · all skills secure"
                }
            }
        }
        let parent = student.parentName?.split(separator: " ").first.map { "\($0)'s" } ?? "their parent's"
        return MarkedRow(
            id: student.id, initials: student.initials, name: student.name, line: line, gapReportID: report?.id,
            working: working, canReport: agreed && mark != nil && !working, canMark: agreed,
            consentLine: agreed ? nil : "Marking waits for \(parent) consent"
        )
    }

    /// The days after the mock ("What the mocks showed": each used report's line for the day, by student) and the test.
    private func lastDayRows(
        _ item: SchoolItem, split: [PreparationDay], students: [Student], reports: [Artefact],
        pending: (waiting: String?, none: String)
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
            let words = lines + [pending.waiting].compactMap(\.self)
            return lastRow(
                day.day,
                title: "What the mocks showed",
                line: words.isEmpty ? pending.none : words.joined(separator: " · "),
                changed: !lines.isEmpty
            )
        }
        return rows + [lastRow(item.date, title: "The test", line: "")]
    }

    /// The words after the used reports' lines: the students whose report the live job is still working out
    /// (P21-Exam-GapWorking, "Dev's lines follow once his marks are read"), and the line when there are none (none
    /// marked yet: P21-Exam-MockMaking, -MockFailed).
    nonisolated static func pendingWords(
        _ students: [Student], reports: [Artefact], marks: [MarkRecord], jobWorks: Bool
    ) -> (waiting: String?, none: String) {
        let coming = students.filter { student in
            jobWorks && marks.contains { $0.studentID == student.id }
                && !reports.contains { $0.studentID == student.id } && student.consent != nil
        }
        let waiting = coming.isEmpty ? nil
            : "\(ListWordsBridge.and(coming.map(\.firstName)))'s lines follow once \(possessive(coming)) marks are read"
        let none = marks.isEmpty ? "The last set from each gap report, once the mocks are marked"
            : "The last set from the gap report"
        return (waiting, none)
    }

    private func lastRow(_ day: Day, title: String, line: String, changed: Bool = false) -> PreparationRowModel {
        PreparationRowModel(
            id: day, day: day.weekdayDayText.split(separator: " ").first.map(String.init) ?? "", date: day.shortText,
            title: title, line: line, mark: changed ? .changed : .none, opens: nil
        )
    }

    /// Try again on a mock the job could not make (P21-Exam-MockFailed): the job is asked again, then the page read
    /// again.
    public func tryAgain() async {
        guard let item, let jobs else { return }
        do {
            _ = try await jobs.requestExamPrep(centre: workspace.centre.id, item: item.id)
        } catch {
            message = "That didn't go through. Check your connection and try again."
            return
        }
        await load()
    }

    /// "his", "her" or "their", by the one student's gender; "their" for several or none known.
    nonisolated static func possessive(_ students: [Student]) -> String {
        guard students.count == 1, let gender = students.first?.gender else { return "their" }
        switch gender {
        case .male: return "his"
        case .female: return "her"
        case .other: return "their"
        }
    }
}
