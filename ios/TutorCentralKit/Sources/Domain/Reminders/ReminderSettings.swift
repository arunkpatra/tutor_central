import Foundation

/// The tutor's reminder choices on this iPhone (Teacher reminders, P7-Reminders): three switches, the class lead, the
/// event lead and the fee day. Kept in `UserDefaults`, never on the server.
public struct ReminderSettings: Hashable, Sendable, Codable {
    /// When an event's reminder fires.
    public enum EventLead: String, CaseIterable, Hashable, Sendable, Codable {
        case minutes15, minutes30, hour1, dayBefore18

        /// "15 min", "30 min", "1 hour", "Day before, 18:00" (the event card's tile and its wheel).
        public var label: String {
            switch self {
            case .minutes15: "15 min"
            case .minutes30: "30 min"
            case .hour1: "1 hour"
            case .dayBefore18: "Day before, 18:00"
            }
        }

        /// Minutes before the start, for the leads counted that way.
        var minutes: Int? {
            switch self {
            case .minutes15: 15
            case .minutes30: 30
            case .hour1: 60
            case .dayBefore18: nil
            }
        }
    }

    /// The class card's wheel: minutes before the class starts.
    public static let classLeads = [5, 10, 15, 30, 60]
    /// The fee card's wheel: the 1st to the 28th, so every month has the day.
    public static let feeDays = Array(1 ... 28)

    public var classOn = true
    public var classMinutesBefore = 15
    public var eventOn = true
    public var eventLead: EventLead = .hour1
    public var feesOn = true
    public var feesDay = 5

    public init() {}

    public var anyOn: Bool {
        classOn || eventOn || feesOn
    }

    /// "15 min", "1 hour" (the class lead's tile and wheel).
    public static func leadLabel(minutes: Int) -> String {
        minutes == 60 ? "1 hour" : "\(minutes) min"
    }
}
