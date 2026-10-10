import Foundation
import Testing
@testable import Domain

struct PlanPatternTests {
    @Test func aPatternRoundTripsByWeekdayKey() throws {
        let kept: [Weekday: PlanPattern] = [.wednesday: PlanPattern(groups: 2, subjects: ["Science", "Mathematics"])]
        let data = try PlanPattern.encode(kept)
        #expect(String(bytes: data, encoding: .utf8)?.contains("\"3\":") == true)
        #expect(try PlanPattern.decode(data) == kept)
    }

    @Test func aReasonHasItsWordsAndTitle() {
        #expect(RegenerateReason.moreSums.words == "more sums")
        #expect(RegenerateReason.moreSums.title == "Making it with more sums")
        #expect(RegenerateReason.easier.title == "Making it easier")
        #expect(RegenerateReason.own("  Use fractions only  ").words == "Use fractions only")
        #expect(RegenerateReason.own(String(repeating: "x", count: 300)).words.storedCount == 200)
        #expect(RegenerateReason.own("y").title == "Making it as you asked")
    }
}
