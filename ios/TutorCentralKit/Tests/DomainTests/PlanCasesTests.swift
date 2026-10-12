import Foundation
import Testing
@testable import Domain

/// The shared plan cases (D80): Domain's rules make each case's expected draft, and the API's port (api/src/plan) is
/// held
/// to the same file. The file is written from these rules (`TC_WRITE_PLAN_CASES`, below) and copied here by `bun
/// contract`.
private let file: PlanCaseFile? = {
    guard let url = Bundle.module.url(forResource: "plan-cases", withExtension: "json", subdirectory: "Cases"),
          let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(PlanCaseFile.self, from: data)
}()

/// The draft a case's input makes, and its named draft when the case names one.
private func made(_ input: InputJSON, named: NamedInput?) throws -> (DraftJSON, DraftJSON?) {
    let draft = try PlanRules.plan(input.planInput())
    guard let named else { return (DraftJSON(draft), nil) }
    var topics: [Int: (chapter: String, skill: String)] = [:]
    for (key, topic) in named.topics {
        if let number = Int(key) {
            topics[number] = (topic.chapter, topic.skill)
        }
    }
    return (DraftJSON(draft), DraftJSON(draft.naming(topics).addingBriefs(for: Set(named.briefChapters))))
}

@Test func theCaseFileIsHereAndHoldsEveryScenario() throws {
    var scenarios = PlanCaseScenarios()
    let file = try #require(file)
    #expect(file.cases.map(\.name) == scenarios.all().map(\.name))
}

@Test(arguments: (file?.cases ?? []).map(\.name))
func everyCaseIsWhatTheRulesMake(name: String) throws {
    let item = try #require(file?.cases.first { $0.name == name })
    let named = item.named.map { NamedInput(topics: $0.topics, briefChapters: $0.briefChapters) }
    let (draft, renamed) = try made(item.input, named: named)
    #expect(draft == item.expected, "\(name)")
    #expect(renamed == item.named?.expected, "\(name), named")
}

/// Writes the case file from the scenarios and these rules: `TEST_RUNNER_TC_WRITE_PLAN_CASES=<path> xcodebuild test
/// -only-testing:DomainTests/writeThePlanCases`, then `bun contract`.
@Test(.enabled(if: ProcessInfo.processInfo.environment["TC_WRITE_PLAN_CASES"] != nil))
func writeThePlanCases() throws {
    var scenarios = PlanCaseScenarios()
    let cases = try scenarios.all().map { scenario in
        let (draft, renamed) = try made(scenario.input, named: scenario.named)
        return PlanCase(
            name: scenario.name, input: scenario.input, expected: draft,
            named: scenario.named.flatMap { asked in
                renamed.map { NamedJSON(topics: asked.topics, briefChapters: asked.briefChapters, expected: $0) }
            }
        )
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let path = try #require(ProcessInfo.processInfo.environment["TC_WRITE_PLAN_CASES"])
    try encoder.encode(PlanCaseFile(cases: cases)).write(to: URL(fileURLWithPath: path))
}
