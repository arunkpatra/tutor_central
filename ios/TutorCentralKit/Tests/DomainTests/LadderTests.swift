import Testing
@testable import Domain

struct LadderTests {
    @Test func theThreeAreasMatchTheDatabaseAndTheBoards() {
        #expect(Ladder.Area.allCases.map(\.rawValue) == ["reading", "writing", "numbers"])
        #expect(Ladder.Area.allCases.map(\.title) == ["Reading", "Writing", "Numbers"])
        #expect(Ladder.Area.reading.steps == ["Letters", "Words", "Sentences", "Paragraph", "Story"])
        #expect(Ladder.Area.writing.steps == ["Traces", "Letters", "Words", "Sentences", "Short text"])
        #expect(Ladder.Area.numbers.steps == ["To 9", "To 99", "Add", "Subtract", "Multiply"])
    }

    @Test func theCurrentStepIsTheFirstNotSecure() {
        #expect(Ladder.currentStep([.secure, .secure, .practising, .notStarted, .notStarted]) == 2)
        #expect(Ladder.currentStep([.notStarted, .notStarted, .notStarted, .notStarted, .notStarted]) == 0)
        #expect(Ladder.currentStep([.secure, .secure, .secure, .secure, .secure]) == nil)
        #expect(Ladder.currentStep([.secure, .revisit, .secure]) == 1)
    }
}
