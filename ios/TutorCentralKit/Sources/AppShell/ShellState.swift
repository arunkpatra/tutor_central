import AITools
import Attendance
import Domain
import Fees
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
    /// Made by the first Students screen and shared by every other; nothing observes the slot itself, so filling it
    /// while a view is built changes nothing on screen.
    @ObservationIgnored var register: RegisterStore?
    /// One mark screen per centre, so a tab switch keeps the date, the class and the unsaved toggles.
    @ObservationIgnored var attendance: AttendanceStore?
    /// One fees store per centre, so a tab switch keeps the month and the filter.
    @ObservationIgnored var fees: FeesStore?
    /// One tasks store per centre, shared by Today's Tasks card and the Tasks screen.
    @ObservationIgnored var tasks: TasksStore?
    /// One AI store per centre: a call outlives its screen, and Recent and History are read once.
    @ObservationIgnored var ai: AIStore?
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
        attendance = nil
        fees = nil
        tasks = nil
        ai?.cancel()
        ai = nil
        centre = nil
    }
}
