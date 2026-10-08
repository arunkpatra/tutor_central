import Foundation
import Testing
@testable import Domain

struct CheckResultTests {
    static func mark(_ number: Int, _ marks: Int, of: Int) -> CheckResult.QuestionMark {
        .init(number: number, text: "Q\(number)", note: "n", marks: marks, of: of, changedFrom: nil)
    }

    static let result = CheckResult(
        questions: [mark(1, 1, of: 1), mark(2, 1, of: 2), mark(3, 2, of: 4)],
        summary: "Sign errors."
    )

    @Test func marksAreClampedAndTheTotalIsTheSum() {
        #expect(Self.result.total == 4 && Self.result.outOf == 7 && abs(Self.result.fraction - 4.0 / 7.0) < 0.001)
        let clamped = CheckResult.clamped(CheckResult(questions: [Self.mark(1, 3, of: 1)], summary: "s"))
        #expect(clamped.questions[0].marks == 1 && clamped.questions[0].note == "n (was 3, over the question's marks)")
        let edited = MarkEdit.set(Self.result, question: 2, to: 2)
        #expect(edited.total == 5 && edited.questions[1].marks == 2 && edited.questions[1].changedFrom == 1)
        #expect(MarkEdit.set(edited, question: 2, to: 1).questions[1].changedFrom == nil, "set back: no change")
        #expect(MarkEdit.set(Self.result, question: 3, to: 9).questions[2].marks == 4)
        #expect(MarkEdit.set(Self.result, question: 3, to: -1).questions[2].marks == 0)
        #expect(MarkEdit.set(Self.result, question: 42, to: 1) == Self.result)
        #expect(MarkEdit.saveLabel(Self.result, studentFirstName: "Hemanth") == "Save to Hemanth's notes")
        #expect(MarkEdit.saveLabel(edited, studentFirstName: "Hemanth") == "Save 5 of 7 to Hemanth's notes")
    }

    @Test func theSchemeSourceKnowsWhenItIsReady() {
        #expect(SchemeSource.paper(generationID: UUID()).isValid)
        #expect(!SchemeSource.typed("   ").isValid && SchemeSource.typed("Q1 (1) b").isValid)
        #expect(!SchemeSource.typed(String(repeating: "x", count: 4001)).isValid && SchemeSource.typedLimit == 4000)
    }
}
