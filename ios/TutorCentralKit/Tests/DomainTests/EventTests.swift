import Foundation
import Testing
@testable import Domain

struct EventTests {
    static func event(
        _ title: String,
        _ day: Int,
        _ start: (Int, Int)? = (11, 0),
        end: (Int, Int)? = (12, 0),
        note: String? = nil
    ) -> CalendarEvent {
        CalendarEvent(
            id: UUID(), title: title, date: Day(year: 2026, month: 10, day: day)!,
            startTime: start.flatMap { TimeOfDay(hour: $0.0, minute: $0.1) }, endTime: end.flatMap { TimeOfDay(
                hour: $0.0,
                minute: $0.1
            ) }, note: note
        )
    }

    @Test func theRowsLine() {
        #expect(Self.event("Parents' meeting", 10).timeRange == "11:00–12:00")
        #expect(Self.event("Parents' meeting", 10, note: "Bring the papers.").line == "Bring the papers.")
        #expect(Self.event("Mock test", 17).line == "11:00–12:00")
        #expect(Self.event("Holiday", 20, nil, end: nil).line == nil && Self.event("Holiday", 20, nil, end: nil)
            .timeRange == nil)
    }

    @Test func comingUpIsTheNextSevenDays() throws {
        let events = [
            Self.event("Later", 18),
            Self.event("Mock test", 17, (10, 0)),
            Self.event("Today's", 10),
            Self.event("Soon", 11, (9, 0)),
            Self.event("Also 11", 11, (8, 0)),
        ]
        let sunday = try #require(Day(year: 2026, month: 10, day: 11))
        // Sunday 11: Monday 12 to Sunday 18 inclusive is seven days.
        #expect(CalendarEvent.comingUp(events, after: sunday, calendar: DayHeading.india).map(\.title) == [
            "Mock test",
            "Later",
        ])
        let saturday = try #require(Day(year: 2026, month: 10, day: 10))
        #expect(CalendarEvent.comingUp(events, after: saturday, calendar: DayHeading.india).map(\.title) == [
            "Also 11",
            "Soon",
            "Mock test",
        ])
        #expect(CalendarEvent.on(saturday, in: events).map(\.title) == ["Today's"])
    }

    @Test func theDraftsRules() throws {
        var draft = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 10)))
        #expect(draft.problems == [.titleMissing] && EventDraft.Problem.titleMissing
            .message == "The event needs a title.")
        draft.title = " Parents' meeting "
        #expect(draft.isValid && draft.trimmedTitle == "Parents' meeting" && draft.trimmedNote == nil)
        draft.startTime = TimeOfDay(hour: 12, minute: 0)
        draft.endTime = TimeOfDay(hour: 11, minute: 0)
        #expect(draft.problems == [.endNotAfterStart] && EventDraft.Problem.endNotAfterStart
            .message == "The event has to end after it starts.")
        draft.endTime = nil
        draft.note = String(repeating: "n", count: 501)
        #expect(draft.problems == [.noteTooLong] && EventDraft.Problem.noteTooLong
            .message == "Keep the note under 500 characters.")
        draft.note = ""
        draft.title = String(repeating: "t", count: 121)
        #expect(draft.problems == [.titleTooLong] && EventDraft.Problem.titleTooLong
            .message == "Keep the title under 120 characters.")
        let back = EventDraft(Self.event("Mock test", 17, note: "Hall A"))
        #expect(back.title == "Mock test" && back.date.day == 17 && back.note == "Hall A" && back.startTime?
            .text == "11:00")
    }
}
