import AITools
import Attendance
import Data
import Domain
import Fees
import Foundation
import Observation
import Students
import Today

/// What the tabs remember while one tutor works in one centre: the selected tab, each tab's stack, Today's store and
/// the register. Leaving the tabs (sign-out) or arriving in another centre starts afresh, so the next tutor never sees
/// the last one's place, greeting or counts. One visit of Check a paper: its routes' id and its store.
struct CheckVisit {
    let id: UUID
    let store: CheckStore
}

/// A visit of Scan register: its number (`TabsState.scanVisits` when it was pushed) and its store.
struct ScanVisit {
    let number: Int
    let store: ScanStore
}

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
    /// The visit of Check a paper in progress, by its routes' id.
    @ObservationIgnored var check: CheckVisit?
    /// The visit of Scan register in progress: its list lives until Add or Back (Phase 6's minor 1).
    @ObservationIgnored var scan: ScanVisit?
    /// The centre's queue of changes made offline (D39), read from its file when the centre arrives, and its runner.
    @ObservationIgnored var queue: ChangeQueue?
    @ObservationIgnored var runner: QueueRunner?
    /// The centre's reminder planner, made on first use.
    @ObservationIgnored var scheduler: ReminderScheduler?
    /// The network as the monitor last said; every root's status line follows it.
    var online = true
    var runState: RunState = .idle
    @ObservationIgnored private var centre: UUID?

    init(tabs: TabsState = TabsState()) {
        self.tabs = tabs
    }

    /// The replay's state as the status line shows it: sending wins; failed changes in the queue show until they
    /// are discarded or sent; a sign-out stop waits for the next sign-in.
    var effectiveRun: RunState {
        if case .sending = runState {
            return runState
        }
        if let failed = queue?.pending.failedCount, failed > 0 {
            return .failed(failed)
        }
        return runState == .signedOut ? .signedOut : .idle
    }

    /// The screens read what the server has now: on coming back to the app and after the queue sent (the owner,
    /// 2026-10-09: what changed meanwhile shows without a pull). Attendance keeps unsaved marks; a read that fails
    /// keeps what is shown.
    /// A student's This week "Today" (U35): the Today tab at its root, scrolled to the batch's plan.
    func openToday(batch: UUID) {
        tabs.paths[.today] = []
        tabs.select(.today)
        today?.focusBatch = batch
    }

    func refreshScreens() async {
        async let today: Void? = today?.load()
        async let tasks: Void? = tasks?.load()
        async let fees: Void? = fees?.reload()
        async let attendance: Void? = attendance?.reload()
        _ = await (today, tasks, fees, attendance)
    }

    /// `files` is where the centre's queue file lives (nil: Application Support).
    func sessionChanged(_ state: SessionStore.State, files: URL?) {
        guard case let .ready(workspace) = state else {
            reset()
            return
        }
        if let centre, centre != workspace.centre.id {
            reset()
        }
        if centre == nil {
            queue = ChangeQueue(centre: workspace.centre.id, directory: files)
        }
        centre = workspace.centre.id
    }

    /// The scan visit is over (Add or Back): its store is let go.
    func endScan() {
        scan = nil
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
        check = nil
        scan = nil
        queue = nil
        runner = nil
        scheduler = nil
        runState = .idle
        centre = nil
    }
}
