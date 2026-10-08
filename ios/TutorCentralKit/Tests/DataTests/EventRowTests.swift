import Domain
import Foundation
import Testing
@testable import Data

/// The fixtures are what the local stack answered as the seed's tutor (2026-10-08): the month's read, an insert's
/// answer and an update's answer.
struct EventRowTests {
    static let json = Data("""
    [{"id":"7982ea30-e329-405b-9505-553372acd666","title":"Parents' meeting","date":"2026-10-10",\
    "start_time":"11:00:00","end_time":"12:00:00","note":"Class 10 parents. Bring the September test papers."},
     {"id":"316303d6-bcd7-400a-9247-7cfac52e681a","title":"Mock test, Class 10","date":"2026-10-17",\
    "start_time":"10:00:00","end_time":"12:00:00","note":null},
     {"id":"47e3b785-98df-4e68-acf1-b277f92147c5","title":"Holiday","date":"2026-10-20",\
    "start_time":null,"end_time":null,"note":null}]
    """.utf8)

    @Test func decodesEvents() throws {
        let events = try SupabaseEventsRepository.decoder.decode([EventRow].self, from: Self.json).map(\.event)
        #expect(events[0].title == "Parents' meeting" && events[0].timeRange == "11:00–12:00")
        #expect(events[0].line == "Class 10 parents. Bring the September test papers.")
        #expect(events[1].note == nil && events[1].line == "10:00–12:00")
        #expect(events[2].startTime == nil && events[2].line == nil)
    }

    @Test func aDateDecodesAsADayNotAMoment() throws {
        // A date column is a day in India whatever the device's zone: no Date, no midnight shift.
        let events = try SupabaseEventsRepository.decoder.decode([EventRow].self, from: Self.json).map(\.event)
        #expect(events[0].date == Day(year: 2026, month: 10, day: 10) && events[0].date.iso == "2026-10-10")
    }

    @Test func aWriteAnswersOneRow() throws {
        let updated = Data("""
        {"id":"47e3b785-98df-4e68-acf1-b277f92147c5","title":"Diwali holiday","date":"2026-10-20",\
        "start_time":null,"end_time":null,"note":null}
        """.utf8)
        let event = try SupabaseEventsRepository.decoder.decode(EventRow.self, from: updated).event
        #expect(event.title == "Diwali holiday" && event.date.day == 20 && event.timeRange == nil)
    }

    @Test func theDraftWritesEveryColumn() throws {
        var draft = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 10)))
        draft.title = " Parents' meeting "
        draft.startTime = TimeOfDay(hour: 11, minute: 0)
        let values = SupabaseEventsRepository.values(draft)
        #expect(values["title"] == .string("Parents' meeting") && values["date"] == .string("2026-10-10"))
        #expect(values["start_time"] == .string("11:00") && values["end_time"] == .null && values["note"] == .null)
    }
}
