import Foundation
import Testing
@testable import Domain

struct GreetingTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar
    }()

    func at(_ hour: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: hour)))
    }

    @Test func bands() throws {
        #expect(try Greeting.text(at: at(6), firstName: "Meera", calendar: calendar) == "Good morning, Meera")
        #expect(try Greeting.text(at: at(11), firstName: "Meera", calendar: calendar) == "Good morning, Meera")
        #expect(try Greeting.text(at: at(12), firstName: "Meera", calendar: calendar) == "Good afternoon, Meera")
        #expect(try Greeting.text(at: at(17), firstName: "Meera", calendar: calendar) == "Good evening, Meera")
        #expect(try Greeting.text(at: at(23), firstName: nil, calendar: calendar) == "Good evening")
    }
}
