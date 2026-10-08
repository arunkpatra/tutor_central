import Testing
@testable import Domain

struct TimeUntilTests {
    @Test func theRelativeWords() {
        #expect(TimeUntil.text(minutes: 0) == "starts now" && TimeUntil.text(minutes: -3) == "starts now")
        #expect(TimeUntil.text(minutes: 1) == "in 1 min" && TimeUntil.text(minutes: 25) == "in 25 min" && TimeUntil
            .text(minutes: 59) == "in 59 min")
        #expect(TimeUntil.text(minutes: 60) == "in 1 h" && TimeUntil.text(minutes: 90) == "in 1 h 30 min" && TimeUntil
            .text(minutes: 75) == "in 1 h 15 min")
        #expect(TimeUntil.text(minutes: 120) == "in 2 h")
    }
}
