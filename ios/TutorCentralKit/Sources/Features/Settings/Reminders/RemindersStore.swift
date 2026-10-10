import Data
import Domain
import Foundation
import Observation

/// Teacher reminders (P7-Reminders-*): the permission, the tutor's choices (saved on this iPhone at once, then the
/// reminders planned again), what is set and its last day. The system's ask is made from Turn on reminders only.
@MainActor @Observable public final class RemindersStore {
    /// The line at the top: the next reminder, every switch off, or notifications off in iOS; none before the ask.
    public enum Banner: Hashable, Sendable {
        case on(next: String)
        case allOff
        case refused

        public var text: String {
            switch self {
            case let .on(next): "Reminders are on. Next: \(next)."
            case .allOff: "Reminders are allowed, but every switch below is off."
            case .refused: "Notifications are off for Tutor Central."
            }
        }
    }

    /// What is set on this iPhone: "14 reminders set" and "through Fri 23 Oct".
    public struct OnThisPhone: Hashable, Sendable {
        public let count: String
        public let through: String?
    }

    public private(set) var permission: NotificationPermission = .notAsked
    public private(set) var scheduled: [Reminder] = []
    public private(set) var asking = false
    public var settings: ReminderSettings {
        didSet {
            guard settings != oldValue else { return }
            settingsStore.save(settings)
            Task { await refresh() }
        }
    }

    private let notifications: any NotificationCenterClient
    private let settingsStore: ReminderSettingsStore
    private let classNames: @MainActor () -> [String]
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let replan: @MainActor () async -> [Reminder]

    /// `classNames` reads the register's active classes. `replan` is AppShell's scheduler: it plans from the register,
    /// the events and the fees, replaces what is set, and answers the plan.
    public init(
        notifications: any NotificationCenterClient, settingsStore: ReminderSettingsStore,
        classNames: @escaping @MainActor () -> [String],
        now: @escaping @Sendable () -> Date, calendar: Calendar, replan: @escaping @MainActor () async -> [Reminder]
    ) {
        self.notifications = notifications
        self.settingsStore = settingsStore
        self.classNames = classNames
        self.now = now
        self.calendar = calendar
        self.replan = replan
        settings = settingsStore.load()
    }

    public func load() async {
        permission = await notifications.permission()
        await refresh()
    }

    /// The system's ask; allowed plans at once.
    public func turnOn() async {
        guard !asking else { return }
        asking = true
        defer { asking = false }
        settingsStore.asked = true
        permission = await notifications.requestPermission() ? .allowed : .refused
        await refresh()
    }

    /// Refresh: plan again (only when allowed).
    public func refresh() async {
        guard permission == .allowed else {
            scheduled = []
            return
        }
        scheduled = await replan()
    }

    public var banner: Banner? {
        switch permission {
        case .notAsked: nil
        case .refused: .refused
        case .allowed:
            if !settings.anyOn {
                .allOff
            } else if let first = scheduled.min(by: { $0.fireAt < $1.fireAt }) {
                .on(next: "\(first.subject), \(when(first.fireAt))")
            } else {
                .on(next: "nothing in the next two weeks")
            }
        }
    }

    public var onThisPhone: OnThisPhone {
        guard permission == .allowed else { return OnThisPhone(count: "Nothing set", through: nil) }
        guard let last = scheduled.max(by: { $0.fireAt < $1.fireAt }) else {
            return OnThisPhone(count: "No reminders set", through: nil)
        }
        let count = scheduled.count == 1 ? "1 reminder set" : "\(scheduled.count) reminders set"
        return OnThisPhone(count: count, through: "through \(Day(last.fireAt, calendar: calendar).shortWeekdayText)")
    }

    /// "Class 10 Maths and Class 8 Science on their days"; "Your classes on their days" with none. Read each time: the
    /// register may load after the screen opens.
    public var classesLine: String {
        let classNames = classNames()
        guard !classNames.isEmpty else { return "Your classes on their days" }
        let names = classNames.count == 1
            ? classNames[0]
            : classNames.dropLast().joined(separator: ", ") + " and " + classNames[classNames.count - 1]
        return "\(names) on their days"
    }

    /// The three rows' lines before the ask: "1 hour before", "1 hour before", "On the 5th at 09:00".
    public var rowLines: [String] {
        [
            "\(ReminderSettings.leadLabel(minutes: settings.classMinutesBefore)) before",
            settings.eventLead == .dayBefore18 ? "The day before at 18:00" : "\(settings.eventLead.label) before",
            "On the \(feesDayLabel) at 09:00",
        ]
    }

    public var feesDayLabel: String {
        Self.ordinal(settings.feesDay)
    }

    /// "1st", "2nd", "3rd", "4th", "11th", "21st".
    public nonisolated static func ordinal(_ day: Int) -> String {
        let suffix = switch (day % 10, day % 100) {
        case (_, 11 ... 13): "th"
        case (1, _): "st"
        case (2, _): "nd"
        case (3, _): "rd"
        default: "th"
        }
        return "\(day)\(suffix)"
    }

    /// "today at 16:45", "tomorrow at 09:00", "Sat 10 Oct at 10:00".
    private func when(_ date: Date) -> String {
        let day = Day(date, calendar: calendar)
        let today = Day(now(), calendar: calendar)
        let time = QueuedChange.clock(date, calendar: calendar)
        if day == today {
            return "today at \(time)"
        }
        if day == today.adding(days: 1, calendar: calendar) {
            return "tomorrow at \(time)"
        }
        return "\(day.shortWeekdayText) at \(time)"
    }
}
