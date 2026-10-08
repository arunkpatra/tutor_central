/// What the event form holds and checks (New event, Edit event).
public struct EventDraft: Hashable, Sendable {
    public var title = ""
    public var date: Day
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var note = ""

    public static let titleLimit = 120
    public static let noteLimit = 500

    public enum Problem: Hashable, Sendable {
        case titleMissing, titleTooLong, noteTooLong, endNotAfterStart

        public var message: String {
            switch self {
            case .titleMissing: "The event needs a title."
            case .titleTooLong: "Keep the title under 120 characters."
            case .noteTooLong: "Keep the note under 500 characters."
            case .endNotAfterStart: "The event has to end after it starts."
            }
        }
    }

    public init(date: Day) {
        self.date = date
    }

    public init(_ event: CalendarEvent) {
        title = event.title
        date = event.date
        startTime = event.startTime
        endTime = event.endTime
        note = event.note ?? ""
    }

    public var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public var problems: Set<Problem> {
        var found = Set<Problem>()
        if trimmedTitle.isEmpty {
            found.insert(.titleMissing)
        }
        if trimmedTitle.count > Self.titleLimit {
            found.insert(.titleTooLong)
        }
        if (trimmedNote?.count ?? 0) > Self.noteLimit {
            found.insert(.noteTooLong)
        }
        if let startTime, let endTime, endTime <= startTime {
            found.insert(.endNotAfterStart)
        }
        return found
    }

    public var isValid: Bool {
        problems.isEmpty
    }
}
