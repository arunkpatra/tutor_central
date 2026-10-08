import Foundation

/// Where the schedule's rows lead when the screen is another feature's; AppShell supplies them.
public struct ScheduleActions {
    let openClass: (UUID) -> Void

    public init(openClass: @escaping (UUID) -> Void) {
        self.openClass = openClass
    }
}
