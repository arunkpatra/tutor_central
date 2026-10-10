import BackgroundTasks
import Foundation

/// iOS's app refresh (docs/spec-v2.md section 6, D60): registered before launch ends, asked for when the app goes to
/// the
/// background. From Phase 12 the handler makes the day's plan as the user; until then it completes at once.
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
    public static func schedule(earliest: TimeInterval = 4 * 3600) {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliest)
        try? BGTaskScheduler.shared.submit(request)
    }
}
