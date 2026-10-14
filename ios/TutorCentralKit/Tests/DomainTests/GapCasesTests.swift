import Foundation
import Testing
@testable import Domain

/// The gap report's tallies held equal to the exam job's port (api/src/plan/gap.ts, D106) by the shared case file
/// (tools/contract/gap-cases.json, copied here by `bun contract`).
struct GapCaseFile: Decodable {
    struct MockQuestion: Decodable {
        var number: Int
        var marks: Int
        var skill: String
    }

    struct Mark: Decodable {
        var number: Int
        var marks: Int
        var note: String
    }

    struct Tally: Decodable, Equatable {
        var skill: String
        var right: Int
        var of: Int
        var note: String?
    }

    struct Case: Decodable {
        var name: String
        var mock: [MockQuestion]
        var marks: [Mark]
        var tallies: [Tally]
        var weakest: [String]
        var count: Int?
    }

    var cases: [Case]
}

struct GapCasesTests {
    @Test func everySharedGapCaseTalliesAndPicksTheWeakestAsTheJobDoes() throws {
        let url = try #require(Bundle.module.url(
            forResource: "gap-cases",
            withExtension: "json",
            subdirectory: "Cases"
        ))
        let file = try JSONDecoder().decode(GapCaseFile.self, from: Data(contentsOf: url))
        #expect(file.cases.count >= 8)
        for item in file.cases {
            let questions = item.mock.map {
                MockContent.Question(number: $0.number, text: "q", marks: $0.marks, answer: "a", skill: $0.skill)
            }
            let mock = MockContent(
                title: "Mock", durationMinutes: 40,
                sections: [MockContent.Section(name: "A", marksEach: 1, questions: questions)],
                pattern: MockPattern(marks: item.mock.reduce(0) { $0 + $1.marks }, durationMinutes: 40), portions: [],
                schoolItemID: nil
            )
            let marking = CheckResult(questions: item.marks.map {
                CheckResult.QuestionMark(
                    number: $0.number,
                    text: "q",
                    note: $0.note,
                    marks: $0.marks,
                    of: 9,
                    changedFrom: nil
                )
            }, summary: "s")
            let tallies = GapTallies.bySkill(marking, mock: mock)
            let got = tallies.map { GapCaseFile.Tally(skill: $0.skill, right: $0.right, of: $0.of, note: $0.note) }
            #expect(got == item.tallies, "\(item.name)")
            #expect(GapTallies.weakest(tallies, count: item.count ?? 6) == item.weakest, "\(item.name)")
        }
    }
}
