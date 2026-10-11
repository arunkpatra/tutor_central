import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// One of the last days in the gap report (P10-GapReport's The last two days): the day column, the model's title and
/// line.
public struct GapDayRow: Identifiable, Hashable, Sendable {
    public var id: String {
        date + title
    }

    public let day: String
    public let date: String
    public let title: String
    public let line: String
}

/// The gap report after a marked mock (P10-GapReport; plan/phase-13-plan.md decision 15): the kept report, else one
/// made
/// from the student's marking and the mock (the tallies are the app's, the summary and the days the model's) and kept
/// with the exam; Use this plan marks it used and tells the plan.
@MainActor @Observable public final class GapReportStore {
    public enum Stage: Hashable, Sendable { case loading, making, ready, failed(String) }

    public private(set) var stage: Stage = .loading
    public private(set) var report: GapReportContent?
    public private(set) var artefact: Artefact?
    public private(set) var exam: SchoolItem?
    public private(set) var mark: MarkRecord?
    /// The system alert's words for a refused or failed write (U33).
    public var message: String?
    /// Use this plan: today's plan is made again for the student (AppShell's).
    @ObservationIgnored public var onUsed: ((UUID) -> Void)?
    @ObservationIgnored public var online: () async -> Bool = { true }
    public let itemID: UUID
    public let studentID: UUID
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let ai: any AIRepository
    let record: (any RecordRepository)?
    let schoolItems: (any SchoolItemsRepository)?
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        itemID: UUID, studentID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        ai: any AIRepository, record: (any RecordRepository)?, schoolItems: (any SchoolItemsRepository)?,
        now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.itemID = itemID
        self.studentID = studentID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.record = record
        self.schoolItems = schoolItems
        self.now = now
        self.calendar = calendar
    }

    static let readFailed = "Couldn't load the gap report. Check your connection and try again."
    static let makeFailed = "Couldn't make the gap report. Check your connection and try again."

    var centre: UUID {
        workspace.centre.id
    }

    var today: Day {
        Day(now(), calendar: calendar)
    }

    public var student: Student? {
        register.student(studentID)
    }

    public var used: Bool {
        report?.usedAt != nil
    }

    /// The kept report, else a new one: the student's consent first, then the mark and the mock; offline a new one is
    /// refused.
    public func load() async {
        await register.loadIfNeeded()
        exam = await (try? schoolItems?.item(id: itemID, centre: centre)) ?? nil
        let kept: Artefact?
        do {
            kept = try await plans.gapReport(for: itemID, student: studentID, centre: centre)
        } catch {
            stage = .failed(Self.readFailed)
            return
        }
        mark = await (try? record?.marks(centre: centre, students: [studentID]))?
            .filter { $0.schoolItemID == itemID && $0.artefactID != nil }
            .max { $0.date < $1.date }
        if let kept, case let .gapReport(content) = kept.content {
            artefact = kept
            report = content
            stage = .ready
            return
        }
        await make()
    }

    private func make() async {
        guard let student else {
            stage = .failed(Self.readFailed)
            return
        }
        guard student.consent != nil else {
            stage = .failed(Self.waitsForConsent(student))
            return
        }
        guard await online() else {
            stage = .failed(OfflineRefusal.words(for: .gapReport))
            return
        }
        guard let mark, let mockID = mark.artefactID,
              let mock = await (try? plans.artefact(id: mockID, centre: centre)) ?? nil,
              case let .mock(content) = mock.content else {
            stage = .failed("Mark \(student.firstName)'s mock first; the gap report reads the marks.")
            return
        }
        stage = .making
        let tallies = GapTallies.bySkill(CheckResult(questions: mark.questions ?? [], summary: ""), mock: content)
        let request = GapRequest(
            studentID: studentID, classLevel: student.classLevel ?? .eight, subject: exam?.subject ?? mark.subject,
            daysLeft: max(1, today.days(to: exam?.date ?? today)), bySkill: tallies
        )
        do {
            let made = try await ai.makeGapReport(request, centre: centre)
            let content = GapReportContent(
                summary: made.summary, bySkill: tallies, days: made.days, usedAt: nil, score: mark.score,
                max: mark.max, schoolItemID: itemID
            )
            artefact = try await plans.keep(
                NewArtefact(
                    kind: .gapReport, source: .made, title: "After the mock", content: .gapReport(content),
                    photoPath: nil, generationID: made.generationID, regeneratedFrom: nil
                ),
                to: ArtefactLink(item: itemID, student: studentID), centre: centre
            )
            report = content
            stage = .ready
        } catch {
            stage = .failed(Self.makeFailed)
        }
    }

    /// "Dev's gap report waits for Ramesh's consent. Record it on Dev's page."
    static func waitsForConsent(_ student: Student) -> String {
        let parent = student.parentName?.split(separator: " ").first.map { "\($0)'s" } ?? "their parent's"
        let name = student.firstName
        return "\(name)'s gap report waits for \(parent) consent. Record it on \(name)'s page."
    }

    // MARK: - The hero

    /// "Dev Kumar · Science mock · marked Wed 14 Oct".
    public var eyebrow: String {
        let subject = exam?.subject ?? mark?.subject ?? ""
        return [
            student?.name,
            subject.isEmpty ? "The mock" : "\(subject) mock",
            mark.map { "marked \($0.date.shortWeekdayText)" },
        ]
        .compactMap(\.self).joined(separator: " · ")
    }

    public var score: Int {
        report?.score ?? mark?.score ?? 0
    }

    public var of: Int {
        report?.max ?? mark?.max ?? 0
    }

    /// "The test is on Friday. Two days left."; "The test is tomorrow."; "The test is today."
    public var line: String {
        guard let exam else { return "" }
        let days = today.days(to: exam.date)
        let weekday = exam.date.weekdayLongText.split(separator: " ").first.map(String.init) ?? ""
        switch days {
        case ...0: return "The test is today."
        case 1: return "The test is tomorrow, \(weekday)."
        default: return "The test is on \(weekday). \(Self.daysLeft(days))"
        }
    }

    /// "Two days left."; past nine, "12 days left."
    static func daysLeft(_ days: Int) -> String {
        let words = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        let number = (1 ... words.count).contains(days) ? words[days - 1] : "\(days)"
        return "\(number) \(days == 1 ? "day" : "days") left."
    }

    /// The model's days on the days from tomorrow to the test.
    public var days: [GapDayRow] {
        guard let report else { return [] }
        let last = exam?.date ?? today
        return report.days.enumerated().map { index, plan in
            let candidate = today.adding(days: index + 1, calendar: calendar)
            let day = min(candidate, last)
            let weekday = day.weekdayDayText.split(separator: " ").first.map(String.init) ?? ""
            return GapDayRow(day: weekday, date: day.shortText, title: plan.title, line: plan.line)
        }
    }

    /// The batch whose plan Change opens on Today.
    public var batchID: UUID? {
        student?.classID
    }

    // MARK: - Use this plan

    /// The report marked used; the plan reads its lines for the days after the mock (PlanMaker) and is made again.
    public func use() async -> Bool {
        guard var content = report, let artefact else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .gapReport)
            return false
        }
        content.usedAt = now()
        do {
            try await plans.setContent(.gapReport(content), artefact: artefact.id, centre: centre)
        } catch {
            message = "That didn't go through. Check your connection and try again."
            return false
        }
        report = content
        onUsed?(studentID)
        return true
    }
}
