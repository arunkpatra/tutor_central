import Data
import Domain
import Foundation

/// Plans the tutor's reminders from the register's classes, the next two weeks' events and this month's fees still
/// due, and replaces what is set on this iPhone (only when allowed). Run on foreground, after a sign-in, after a class,
/// an event or a fee changes, and from Teacher reminders. One run at a time.
@MainActor final class ReminderScheduler {
    private let notifications: any NotificationCenterClient
    private let settingsStore: ReminderSettingsStore
    private let register: any Register
    private let events: any EventsRepository
    private let fees: any FeesRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var running: Task<[Reminder], Never>?

    init(
        notifications: any NotificationCenterClient, settingsStore: ReminderSettingsStore, register: any Register,
        events: any EventsRepository, fees: any FeesRepository, now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
        self.notifications = notifications
        self.settingsStore = settingsStore
        self.register = register
        self.events = events
        self.fees = fees
        self.now = now
        self.calendar = calendar
    }

    /// The plan; set on this iPhone when allowed. A read that fails keeps the reminders of its kind already set. A call
    /// made while a run is under way waits for it and plans
    /// again, so a change made meanwhile is never answered with the older plan; calls that waited together share one.
    @discardableResult func replan(workspace: Workspace) async -> [Reminder] {
        if let previous = running {
            _ = await previous.value
            // Another waiter may have started the fresh run already.
            if let fresh = running, fresh != previous {
                return await fresh.value
            }
        }
        let task = Task { await plan(workspace) }
        running = task
        let plan = await task.value
        if running == task {
            running = nil
        }
        return plan
    }

    private func plan(_ workspace: Workspace) async -> [Reminder] {
        await register.loadIfNeeded()
        let start = now()
        let today = Day(start, calendar: calendar)
        let centre = workspace.centre.id
        let settings = settingsStore.load()
        let upcoming = try? await events.events(
            centre: centre, from: today, to: today.adding(days: ReminderPlanner.days, calendar: calendar)
        )
        let month = Period.containing(start, in: calendar.timeZone)
        let invoices = try? await fees.invoices(centre: centre, month: month)
        let due = (invoices ?? []).filter { $0.status == .due }
        let counts = Dictionary(grouping: register.activeStudents.compactMap(\.classID)) { $0 }.mapValues(\.count)
        let input = ReminderInput(
            classes: register.activeClasses, memberCounts: counts, events: upcoming ?? [],
            dueFees: due.isEmpty ? nil : DueFees(count: due.count, total: due.map(\.amount).total),
            settings: settings
        )
        guard await notifications.permission() == .allowed else { return [] }
        // A read that failed (offline) keeps what was set for that kind rather than dropping it (review I3).
        var unread: Set<Reminder.Kind> = []
        if upcoming == nil, settings.eventOn {
            unread.insert(.event)
        }
        if invoices == nil, settings.feesOn {
            unread.insert(.fees)
        }
        let plan = await keeping(unread, in: ReminderPlanner.plan(input, now: start, calendar: calendar), after: start)
        await notifications.replace(with: plan)
        return plan
    }

    /// The plan with the pending reminders of the kinds it could not read, still ahead, the soonest 60 in all.
    private func keeping(_ kinds: Set<Reminder.Kind>, in plan: [Reminder], after start: Date) async -> [Reminder] {
        guard !kinds.isEmpty else { return plan }
        let kept = await notifications.pending().filter { kinds.contains($0.kind) && $0.fireAt > start }
        return Array((plan + kept).sorted { $0.fireAt < $1.fireAt }.prefix(ReminderPlanner.limit))
    }
}
