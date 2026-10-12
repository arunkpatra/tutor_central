import Data
import Domain
import Foundation
import Observation

/// Teacher reminders (P18-Reminders; P7-Reminders-NotAsked, -AllOff, -Refused, -DayPicker): the permission, the
/// tutor's choices kept with the account and saved as each changes, and the next reminder the server will send. The
/// system's ask is made from Turn on reminders only; once allowed, the iPhone registers for the server's pushes.
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

    public private(set) var permission: NotificationPermission = .notAsked
    public private(set) var next: NextReminder?
    public private(set) var asking = false
    /// The words of a failed save, for the system's alert (feedback.md); the switch goes back.
    public var alert: String?
    public var settings: ReminderSettings {
        didSet {
            guard loaded, settings != oldValue, !saving else { return }
            Task { await saveChanges() }
        }
    }

    private var loaded = false
    /// The choices the account holds (the last read or save): a failed save puts these back.
    private var confirmed = ReminderSettings()
    /// One save at a time, each of the latest choices: saves running side by side could land out of order and leave
    /// the account on an earlier choice (the review's R-app-3).
    private var saving = false
    private let notifications: any NotificationCenterClient
    private let repository: any ReminderSettingsRepository
    private let centre: UUID
    private let classNames: @MainActor () -> [String]
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let onAllowed: @MainActor () async -> Void

    /// `classNames` reads the register's active classes. `onAllowed` registers this iPhone for the server's pushes once
    /// the tutor allows notifications.
    public init(
        notifications: any NotificationCenterClient, repository: any ReminderSettingsRepository, centre: UUID,
        classNames: @escaping @MainActor () -> [String], now: @escaping @Sendable () -> Date, calendar: Calendar,
        onAllowed: @escaping @MainActor () async -> Void
    ) {
        self.notifications = notifications
        self.repository = repository
        self.centre = centre
        self.classNames = classNames
        self.now = now
        self.calendar = calendar
        self.onAllowed = onAllowed
        settings = ReminderSettings()
    }

    /// The permission, the account's choices (the defaults when they cannot be read) and the next reminder.
    public func load() async {
        permission = await notifications.permission()
        if let read = try? await repository.read(centre: centre) {
            settings = read
        }
        confirmed = settings
        loaded = true
        next = try? await repository.next(centre: centre)
    }

    /// The system's ask; allowed registers for pushes at once.
    public func turnOn() async {
        guard !asking else { return }
        asking = true
        defer { asking = false }
        permission = await notifications.requestPermission() ? .allowed : .refused
        if permission == .allowed {
            await onAllowed()
        }
    }

    /// The choices saved with the account until it holds what is shown; a save that fails puts back what the account
    /// holds and says so.
    private func saveChanges() async {
        saving = true
        defer { saving = false }
        while settings != confirmed {
            let changed = settings
            do {
                try await repository.save(changed, centre: centre)
                confirmed = changed
            } catch {
                loaded = false
                settings = confirmed
                loaded = true
                alert = "That didn't go through. Check your connection and try again."
                return
            }
        }
        next = try? await repository.next(centre: centre)
    }

    public var banner: Banner? {
        switch permission {
        case .notAsked: nil
        case .refused: .refused
        case .allowed:
            if !settings.anyOn {
                .allOff
            } else if let next {
                .on(next: "\(next.subject), \(when(next.at))")
            } else {
                .on(next: "nothing in the next day")
            }
        }
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
