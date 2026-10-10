import Foundation
import Testing
@testable import Domain

struct NextClassTests {
    static let calendar = DayHeading.india
    static let maths = Classroom(
        id: UUID(), name: "Class 10 Maths", subject: nil, monthlyFee: nil, meetingDays: [.monday, .wednesday, .friday],
        startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 0), archivedAt: nil
    )
    static let science = Classroom(
        id: UUID(), name: "Class 8 Science", subject: nil, monthlyFee: nil, meetingDays: [.tuesday, .thursday],
        startTime: TimeOfDay(hour: 16, minute: 30), endTime: TimeOfDay(hour: 17, minute: 30), archivedAt: nil
    )
    static func at(_ day: Int, _ hour: Int, _ minute: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    let classes = [maths, science]

    @Test func theNextClassAcrossTheDay() {
        // Wednesday 7 October 2026.
        #expect(NextClass.find(in: classes, now: Self.at(7, 16, 35), calendar: Self.calendar) == .soon(
            Self.maths,
            startsIn: 25
        ))
        #expect(NextClass.find(in: classes, now: Self.at(7, 17, 30), calendar: Self.calendar) == .running(
            Self.maths,
            endsAt: TimeOfDay(hour: 18, minute: 0)
        ))
        #expect(NextClass.find(in: classes, now: Self.at(7, 18, 1), calendar: Self.calendar) == .tomorrow(Self.science))
        #expect(NextClass.find(in: classes, now: Self.at(7, 9, 30), calendar: Self.calendar) == .laterToday(
            Self.maths,
            at: TimeOfDay(hour: 17, minute: 0)
        ))
        #expect(
            NextClass.find(in: classes, now: Self.at(7, 15, 30), calendar: Self.calendar) == .soon(
                Self.maths,
                startsIn: 90
            ),
            "90 min is the edge"
        )
        #expect(NextClass.find(in: classes, now: Self.at(7, 15, 29), calendar: Self.calendar) == .laterToday(
            Self.maths,
            at: TimeOfDay(hour: 17, minute: 0)
        ))
    }

    @Test func sundayNightLooksToMonday() throws {
        let sunday = Self.at(11, 23, 59)
        #expect(NextClass.find(in: classes, now: sunday, calendar: Self.calendar) == .tomorrow(Self.maths))
        let saturday = Self.at(10, 9, 30)
        #expect(try NextClass.find(in: classes, now: saturday, calendar: Self.calendar) == .onDay(
            Self.maths,
            #require(Day(year: 2026, month: 10, day: 12))
        ))
    }

    @Test func aClassWithoutATimeHasNoCountdown() {
        var loose = Self.maths
        loose.startTime = nil
        loose.endTime = nil
        #expect(NextClass.find(in: [loose], now: Self.at(7, 16, 35), calendar: Self.calendar) == .laterToday(
            loose,
            at: nil
        ))
        #expect(
            NextClass.find(in: [loose], now: Self.at(7, 23, 0), calendar: Self.calendar) == .laterToday(loose, at: nil),
            "a timeless class is today's until midnight"
        )
        var archived = Self.maths
        archived.archivedAt = Date()
        #expect(NextClass.find(in: [archived], now: Self.at(7, 16, 35), calendar: Self.calendar) == nil)
        #expect(NextClass.find(in: [], now: Self.at(7, 16, 35), calendar: Self.calendar) == nil)
    }

    @Test func theWordsOnTheHero() throws {
        #expect(NextClass.soon(Self.maths, startsIn: 25).eyebrow == "Next batch · in 25 min")
        #expect(NextClass.running(Self.maths, endsAt: TimeOfDay(hour: 18, minute: 0)).eyebrow == "Now · until 18:00")
        #expect(NextClass.running(Self.maths, endsAt: nil).eyebrow == "Now")
        #expect(NextClass.laterToday(Self.maths, at: TimeOfDay(hour: 17, minute: 0)).eyebrow == "Next batch · 17:00")
        #expect(NextClass.laterToday(Self.maths, at: nil).eyebrow == "Next batch · today")
        #expect(NextClass.tomorrow(Self.science).eyebrow == "Next batch · tomorrow")
        #expect(try NextClass.onDay(Self.maths, #require(Day(year: 2026, month: 10, day: 12)))
            .eyebrow == "No batch today")
        #expect(NextClass.soon(Self.maths, startsIn: 25).canMark && NextClass.running(Self.maths, endsAt: nil).canMark)
        #expect(!NextClass.tomorrow(Self.science).canMark && !NextClass.laterToday(Self.maths, at: nil).canMark)
    }

    @Test func todaysClassesByStartTime() throws {
        var evening = Self.science
        evening.meetingDays = [.wednesday]
        let today = try #require(Day(year: 2026, month: 10, day: 7))
        let list = NextClass.classesToday(in: [Self.maths, evening], on: today, calendar: Self.calendar)
        #expect(list.map(\.name) == ["Class 8 Science", "Class 10 Maths"], "16:30 before 17:00")
        #expect(try NextClass.classesToday(
            in: classes,
            on: #require(Day(year: 2026, month: 10, day: 10)),
            calendar: Self.calendar
        ).isEmpty)
    }
}
