import BackgroundTasks
import Foundation

/// iOS's app refresh (docs/spec-v2.md section 6, D60): registered before launch ends, asked for when the app goes to
/// the background, for 06:00 the next morning. The handler makes the day's plans as the user (AppShell's
/// `RefreshHandler`); iOS decides whether it runs.
public enum BackgroundRefresh {
    public static let identifier = "in.tutorcentral.app.refresh"

    @MainActor public static func register(handler: @escaping @Sendable () async -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            let work = Task {
                await handler()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = { work.cancel() }
        }
    }

    /// iOS decides when, if at all; a refused request (the simulator, Background App Refresh off) changes nothing.
    public static func schedule(at date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = date
        try? BGTaskScheduler.shared.submit(request)
    }

    /// 06:00 the day after `date`, in the calendar's zone.
    public static func nextMorning(after date: Date, calendar: Calendar) -> Date {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
