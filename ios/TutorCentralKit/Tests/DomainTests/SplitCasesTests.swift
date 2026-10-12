import Foundation
import Testing
@testable import Domain

/// The exam split's shared cases (D80): Domain's rules make each split, and the API's port is held to the same file
/// (api/test/budget-cases.test.ts). Written from these rules (`TC_WRITE_SPLIT_CASES`, below) and copied here by
/// `bun contract`.
private let file = CaseJSON.read("budget-cases", as: SplitCaseFile.self)

/// One student's exam day as the plan reads it: on holiday, else the nearest exam's split from its start.
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

@Test func theCaseFileIsHereAndHoldsEverySplitScenario() throws {
    var splits = SplitCaseScenarios()
    let file = try #require(file)
    #expect(file.splits.map(\.name) == splits.all().map(\.name))
}

@Test(arguments: (file?.splits ?? []).map(\.name))
func everySplitIsWhatTheRulesMake(name: String) throws {
    let item = try #require(file?.splits.first { $0.name == name })
    #expect(try split(item.input) == item.expected, "\(name)")
}

/// Writes the splits into the case file from the scenarios and these rules, its budget cases kept as they are:
/// `TEST_RUNNER_TC_WRITE_SPLIT_CASES=tools/contract/budget-cases.json xcodebuild test
/// -only-testing:DomainTests/writeTheSplitCases`, then `bun contract`.
@Test(.enabled(if: ProcessInfo.processInfo.environment["TC_WRITE_SPLIT_CASES"] != nil))
func writeTheSplitCases() throws {
    var splits = SplitCaseScenarios()
    let made = try splits.all().map { try SplitCase(name: $0.name, input: $0.input, expected: split($0.input)) }
    let path = try #require(ProcessInfo.processInfo.environment["TC_WRITE_SPLIT_CASES"])
    let url = URL(fileURLWithPath: path)
    var whole = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    whole["splits"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(made))
    try JSONSerialization.data(withJSONObject: whole, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        .write(to: url)
}
