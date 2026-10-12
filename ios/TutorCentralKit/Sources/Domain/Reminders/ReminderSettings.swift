import Foundation

/// The tutor's reminder choices (Teacher reminders, P18-Reminders): the class, event and fee switches with the class
/// lead, the event lead and the fee day, and Plan ready and Notes ready. Kept with the account (`reminder_settings`,
/// plan/phase-18-plan.md decision 6); the server plans and sends what they choose.
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
    /// An hour before the batch (the plan's reminder, Phase 12); a tutor who set a lead keeps it.
    public var classMinutesBefore = 60
    public var eventOn = true
    public var eventLead: EventLead = .hour1
    public var feesOn = true
    public var feesDay = 5
    /// When each batch's plan and material are made (Phase 18).
    public var planReady = true
    /// When the note day's notes are written (Phase 18).
    public var notesReady = true

    public init() {}

    /// Builds 27 and earlier kept the six choices before Plan ready and Notes ready: those read as on.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ReminderSettings()
        classOn = try c.decodeIfPresent(Bool.self, forKey: .classOn) ?? defaults.classOn
        classMinutesBefore = try c.decodeIfPresent(Int.self, forKey: .classMinutesBefore) ?? defaults.classMinutesBefore
        eventOn = try c.decodeIfPresent(Bool.self, forKey: .eventOn) ?? defaults.eventOn
        eventLead = try c.decodeIfPresent(EventLead.self, forKey: .eventLead) ?? defaults.eventLead
        feesOn = try c.decodeIfPresent(Bool.self, forKey: .feesOn) ?? defaults.feesOn
        feesDay = try c.decodeIfPresent(Int.self, forKey: .feesDay) ?? defaults.feesDay
        planReady = try c.decodeIfPresent(Bool.self, forKey: .planReady) ?? defaults.planReady
        notesReady = try c.decodeIfPresent(Bool.self, forKey: .notesReady) ?? defaults.notesReady
    }

    public var anyOn: Bool {
        classOn || eventOn || feesOn || planReady || notesReady
    }

    /// "15 min", "1 hour" (the class lead's tile and wheel).
    public static func leadLabel(minutes: Int) -> String {
        minutes == 60 ? "1 hour" : "\(minutes) min"
    }
}
