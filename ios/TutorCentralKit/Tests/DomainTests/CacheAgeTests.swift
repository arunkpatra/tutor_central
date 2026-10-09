import Domain
import Foundation
import Testing

struct CacheAgeTests {
    let calendar = DayHeading.india

    func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? Date()
    }

    @Test func todayYesterdayAndEarlier() {
        let now = at(7, 16, 35)
        #expect(CacheAge.words(savedAt: at(7, 14, 10), now: now, calendar: calendar)
            == "Offline. Showing what was saved at 14:10.")
        #expect(CacheAge.words(savedAt: at(6, 18, 30), now: now, calendar: calendar)
            == "Offline. Showing what was saved yesterday at 18:30.")
        #expect(CacheAge.words(savedAt: at(5, 9, 0), now: now, calendar: calendar)
            == "Offline. Showing what was saved on Mon 5 Oct.")
    }
}
