import Foundation
import Testing
@testable import Domain

/// The shared budget cases (D80): Domain's rules make each case's requests and each split, and the API's port is held
/// to
/// the same file (api/test/budget-cases.test.ts). Written from these rules (`TC_WRITE_BUDGET_CASES`, below) and copied
/// here by `bun contract`.
private let file = CaseJSON.read("budget-cases", as: BudgetCaseFile.self)

/// The requests a case's input makes, with the spaced queue's picks taken as the plan maker took them (each member's
/// pick in their group's subject) and the exam material from the input's revision lines.
private func requests(_ input: BudgetCase.Input) throws -> [RequestJSON] {
    let plan = try input.plan.planInput()
    let draft = PlanRules.plan(plan)
    let now = try CaseJSON.instant(input.now)
    var spaced: [UUID: [Skill]] = [:]
    for group in draft.groups {
        for member in group.memberIDs {
            let chapters = (plan.chapters[member] ?? []).filter { $0.subject == group.subject }
            let ids = Set(chapters.map(\.id))
            let skills = (plan.skills[member] ?? []).filter { ids.contains($0.chapterID) }
            spaced[member] = SpacedQueue.pick(skills: skills, chapters: chapters, now: now, calendar: DayHeading.india)
        }
    }
    let exam = try ExamMaterial(
        revisions: plan.revisions, mocksMade: Set(input.mocksMade.map(CaseJSON.uuid)),
        gapSkills: plan.revisions.compactMapValues { $0.gapSkills.isEmpty ? nil : $0.gapSkills }
    )
    let students = Dictionary(plan.students.map { ($0.id, $0) }) { first, _ in first }
    return ArtefactBudget.requests(
        for: draft, students: students, spacedSkills: spaced, briefsMade: Set(input.briefsMade), exam: exam
    ).map(RequestJSON.init)
}

/// One student's exam day as the plan maker reads it: on holiday, else the nearest exam's split from its start.
private func split(_ input: SplitCase.Input) throws -> SplitCase.Expected {
    let made = try input.domain()
    let (items, student) = (made.items, made.student)
    let today = try CaseJSON.day(input.today)
    let calendar = DayHeading.india
    let holidays = items.filter { $0.kind == .holiday }
    if HolidayRules.onHoliday(student, on: today, items: holidays, students: [student]) {
        return .init(nearest: nil, onHoliday: true, start: nil, days: [])
    }
    guard let exam = SchoolItemRules.nearestExam(
        for: student, items: items, students: [student], today: today, calendar: calendar
    ) else { return .init(nearest: nil, onHoliday: false, start: nil, days: []) }
    let start = ExamPreparation.start(of: exam, today: today, calendar: calendar)
    let context = PreparationContext(
        batch: made.room, today: start, holidays: holidays, students: [student], calendar: calendar
    )
    let days = ExamPreparation.days(
        exam: exam,
        student: student,
        chapters: made.chapters,
        skills: made.skills,
        context: context
    )
    return .init(
        nearest: CaseJSON.id(exam.id),
        onHoliday: false,
        start: start.iso,
        days: days.map(SplitCase.DayJSON.init)
    )
}

@Test func theBudgetCaseFileIsHereAndHoldsEveryScenario() throws {
    var budget = BudgetCaseScenarios()
    var splits = SplitCaseScenarios()
    let file = try #require(file)
    #expect(file.cases.map(\.name) == budget.all().map(\.name))
    #expect(file.splits.map(\.name) == splits.all().map(\.name))
}

@Test(arguments: (file?.cases ?? []).map(\.name))
func everyBudgetCaseIsWhatTheRulesAskFor(name: String) throws {
    let item = try #require(file?.cases.first { $0.name == name })
    #expect(try requests(item.input) == item.expected, "\(name)")
}

@Test(arguments: (file?.splits ?? []).map(\.name))
func everySplitIsWhatTheRulesMake(name: String) throws {
    let item = try #require(file?.splits.first { $0.name == name })
    #expect(try split(item.input) == item.expected, "\(name)")
}

/// Writes the case file from the scenarios and these rules: `TEST_RUNNER_TC_WRITE_BUDGET_CASES=<path> xcodebuild test
/// -only-testing:DomainTests/writeTheBudgetCases`, then `bun contract`.
@Test(.enabled(if: ProcessInfo.processInfo.environment["TC_WRITE_BUDGET_CASES"] != nil))
func writeTheBudgetCases() throws {
    var budget = BudgetCaseScenarios()
    var splits = SplitCaseScenarios()
    let cases = try budget.all().map { try BudgetCase(name: $0.name, input: $0.input, expected: requests($0.input)) }
    let made = try splits.all().map { try SplitCase(name: $0.name, input: $0.input, expected: split($0.input)) }
    try CaseJSON.write(BudgetCaseFile(cases: cases, splits: made), to: "TC_WRITE_BUDGET_CASES")
}
