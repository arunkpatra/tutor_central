import Domain
import Foundation
import Observation

/// New event and Edit event (P4-Event-New, -Edit): the title, the day, optional start and end, the note. Save is
/// disabled until the draft is valid and, when editing, until something changed.
@MainActor @Observable public final class EventFormStore: Identifiable {
    public enum Mode: Sendable {
        case new(Day)
        case edit(CalendarEvent)
    }

    public let mode: Mode
    public var title: String
    public var date: Day
    public private(set) var startTime: TimeOfDay?
    public private(set) var endTime: TimeOfDay?
    public var note: String
    private let original: EventDraft?

    public init(mode: Mode) {
        self.mode = mode
        let draft = switch mode {
        case let .new(day): EventDraft(date: day)
        case let .edit(event): EventDraft(event)
        }
        title = draft.title
        date = draft.date
        startTime = draft.startTime
        endTime = draft.endTime
        note = draft.note
        if case .edit = mode {
            original = draft
        } else {
            original = nil
        }
    }

    public var heading: String {
        original == nil ? "New event" : "Edit event"
    }

    public var editingID: UUID? {
        if case let .edit(event) = mode {
            return event.id
        }
        return nil
    }

    public var draft: EventDraft {
        var draft = EventDraft(date: date)
        draft.title = title
        draft.startTime = startTime
        draft.endTime = endTime
        draft.note = note
        return draft
    }

    /// A new event once it has a title; an edit once a field differs from what was saved.
    public var isChanged: Bool {
        guard let original else { return !draft.trimmedTitle.isEmpty }
        let now = draft
        return now.trimmedTitle != original.trimmedTitle || now.date != original.date
            || now.startTime != original.startTime || now.endTime != original.endTime
            || now.trimmedNote != original.trimmedNote
    }

    public var canSave: Bool {
        draft.isValid && isChanged
    }

    public var timeError: String? {
        draft.problems.contains(.endNotAfterStart) ? EventDraft.Problem.endNotAfterStart.message : nil
    }

    public var titleError: String? {
        draft.problems.contains(.titleTooLong) ? EventDraft.Problem.titleTooLong.message : nil
    }

    public var noteError: String? {
        draft.problems.contains(.noteTooLong) ? EventDraft.Problem.noteTooLong.message : nil
    }

    /// Clearing the start clears the end: an end alone means nothing.
    public func setStart(_ time: TimeOfDay?) {
        startTime = time
        if time == nil {
            endTime = nil
        }
    }

    /// An end chosen before any start takes a start an hour before it.
    public func setEnd(_ time: TimeOfDay?) {
        endTime = time
        if let time, startTime == nil {
            startTime = TimeOfDay(hour: max(time.hour - 1, 0), minute: time.minute)
        }
    }
}
