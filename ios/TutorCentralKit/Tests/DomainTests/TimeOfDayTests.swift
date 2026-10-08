import Testing
@testable import Domain

struct TimeOfDayTests {
    @Test func parsesTheDatabaseAndTheShortForm() {
        #expect(TimeOfDay(iso: "17:00:00") == TimeOfDay(hour: 17, minute: 0))
        #expect(TimeOfDay(iso: "16:30") == TimeOfDay(hour: 16, minute: 30))
        #expect(TimeOfDay(iso: "24:00") == nil && TimeOfDay(iso: "7pm") == nil && TimeOfDay(hour: 9, minute: 60) == nil)
    }

    @Test func writesTwentyFourHourText() throws {
        #expect(TimeOfDay(hour: 9, minute: 5)?.text == "09:05" && TimeOfDay(hour: 17, minute: 0)!.iso == "17:00")
        #expect(try TimeOfDay.range(
            #require(TimeOfDay(hour: 17, minute: 0)),
            #require(TimeOfDay(hour: 18, minute: 0))
        ) == "17:00–18:00")
        #expect(try #require(TimeOfDay(hour: 16, minute: 30)) < TimeOfDay(hour: 17, minute: 0)!)
    }
}
