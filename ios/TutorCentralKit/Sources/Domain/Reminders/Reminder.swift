import Foundation

/// One local notification the planner wants on this iPhone: its stable id, its words, when it fires and the deep
/// link a tap opens.
public struct Reminder: Hashable, Sendable, Identifiable, Codable {
    public enum Kind: Hashable, Sendable, Codable {
        case classMeeting, event, fees
    }

    /// "class-<uuid>-2026-10-07", "event-<uuid>", "fees-2026-10": the same thing at the same time keeps its id, so a
    /// refresh replaces rather than doubles.
    public let id: String
    public let kind: Kind
    public let title: String
    public let body: String
    public let fireAt: Date
    /// "tutorcentral://attendance?date=2026-10-07&class=<uuid>", "tutorcentral://event/<uuid>",
    /// "tutorcentral://fees?month=2026-10".
    public let link: String
    /// What it is about: the class's name, the event's title, "Fees still due" (Teacher reminders' "Next:" line).
    public let subject: String

    public init(id: String, kind: Kind, title: String, body: String, fireAt: Date, link: String, subject: String = "") {
        self.subject = subject
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.fireAt = fireAt
        self.link = link
    }
}

/// This month's fees still due: how many and how much (the fee reminder's words).
public struct DueFees: Hashable, Sendable {
    public let count: Int
    public let total: Money

    public init(count: Int, total: Money) {
        self.count = count
        self.total = total
    }
}

/// What the planner reads: the active classes (callers drop archived ones), students per class, the events, the
/// fees still due (nil when none) and the tutor's choices.
public struct ReminderInput: Sendable {
    public let classes: [Classroom]
    public let memberCounts: [UUID: Int]
    public let events: [CalendarEvent]
    public let dueFees: DueFees?
    public let settings: ReminderSettings

    public init(
        classes: [Classroom], memberCounts: [UUID: Int], events: [CalendarEvent], dueFees: DueFees?,
        settings: ReminderSettings
    ) {
        self.classes = classes
        self.memberCounts = memberCounts
        self.events = events
        self.dueFees = dueFees
        self.settings = settings
    }
}
