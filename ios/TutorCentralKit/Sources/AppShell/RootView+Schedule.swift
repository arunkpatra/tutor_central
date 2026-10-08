import Schedule
import SwiftUI

/// The schedule's wiring: pushed from More and from Today, or opened by an event link with its Edit sheet up.
extension RootView {
    @ViewBuilder func scheduleView(openEvent: UUID?) -> some View {
        if case let .ready(workspace) = session.state {
            ScheduleView(
                store: ScheduleStore(
                    workspace: workspace, register: register(for: workspace), events: deps.events,
                    attendance: deps.attendance, now: deps.now
                ),
                actions: ScheduleActions(openClass: { shell.tabs.push(.classroom($0)) }),
                boardState: launch.flatMap(Self.scheduleBoardState),
                openEvent: openEvent,
                onMissingEvent: { toasts.show("That event is no longer here.") }
            )
        }
    }
}
