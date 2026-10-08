import Domain
import Foundation
import Observation
import Students
import Today

/// What the tabs remember while one tutor works in one centre: the selected tab, each tab's stack, Today's store and
/// the register.
/// Leaving the tabs (sign-out) or arriving in another centre starts afresh, so the next tutor never sees the last
/// one's place, greeting or counts.
@MainActor @Observable final class ShellState {
    var tabs: TabsState
    var today: TodayStore?
    var register: RegisterStore?
    private var centre: UUID?

    init(tabs: TabsState = TabsState()) {
        self.tabs = tabs
    }

    func sessionChanged(_ state: SessionStore.State) {
        guard case let .ready(workspace) = state else {
            reset()
            return
        }
        if let centre, centre != workspace.centre.id {
            reset()
        }
        centre = workspace.centre.id
    }

    private func reset() {
        tabs = TabsState()
        today = nil
        register = nil
        centre = nil
    }
}
