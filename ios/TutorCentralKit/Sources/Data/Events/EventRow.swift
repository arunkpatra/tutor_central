import Domain
import Foundation

/// A `calendar_events` row. `date` is a day, never a moment (Review Focus 5).
struct EventRow: Decodable {
    let id: UUID
    let title: String
    let date: String
    let startTime: String?
    let endTime: String?
    let note: String?

    var event: CalendarEvent {
        CalendarEvent(
            id: id, title: title, date: Day(iso: date) ?? Day(year: 1970, month: 1, day: 1)!,
            startTime: startTime.flatMap(TimeOfDay.init(iso:)), endTime: endTime.flatMap(TimeOfDay.init(iso:)),
            note: note
        )
    }
}
