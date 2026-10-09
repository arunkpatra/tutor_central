import Data
import DesignSystem
import Domain
import Foundation

/// Where the replay of the queue stands (D39), for every root's status line.
enum RunState: Hashable, Sendable {
    case idle
    case sending(Int)
    case failed(Int)
    /// A 401 stopped the run: the changes wait for the next sign-in.
    case signedOut

    static func after(_ outcome: RunOutcome) -> RunState {
        switch outcome {
        case let .done(_, failed): failed > 0 ? .failed(failed) : .idle
        case .offline: .idle
        case .signedOut: .signedOut
        }
    }

    /// "3 saved changes sent." when anything went; the toast is AppShell's, on whichever screen is open.
    static func toast(for outcome: RunOutcome) -> String? {
        let sent = switch outcome {
        case let .done(sent, _), let .offline(sent), let .signedOut(sent): sent
        }
        guard sent > 0 else { return nil }
        return sent == 1 ? "1 saved change sent." : "\(sent) saved changes sent."
    }
}

extension StatusLineModel {
    /// "Offline. Showing what was saved at 14:10." (`CacheAge`), or "Offline. Nothing saved on this iPhone yet."
    static func offline(savedAt: Date?, now: Date, calendar: Calendar) -> StatusLineModel {
        StatusLineModel(
            text: savedAt.map { CacheAge.words(savedAt: $0, now: now, calendar: calendar) }
                ?? "Offline. Nothing saved on this iPhone yet.",
            symbol: "wifi.slash"
        )
    }

    static func sending(_ count: Int) -> StatusLineModel {
        StatusLineModel(
            text: "Back online. Sending \(count) saved \(count == 1 ? "change" : "changes")…", symbol: "",
            spinner: true
        )
    }

    static func failed(_ count: Int, open: @escaping @MainActor () -> Void) -> StatusLineModel {
        StatusLineModel(
            text: "\(count) saved \(count == 1 ? "change" : "changes") couldn't be sent.",
            symbol: "exclamationmark.circle", tone: .overdue, action: open
        )
    }

    static var signInAgain: StatusLineModel {
        StatusLineModel(text: "Sign in again to send your saved changes.", symbol: "clock", tone: .due)
    }
}

/// What a root's status line is chosen from: the replay, the network, the root's last read and its copy's time.
struct LineInputs {
    let run: RunState
    let online: Bool
    /// The root's last read failed for the network (a captive network while the monitor says online).
    let offlineRead: Bool
    /// When the copy on screen was saved; nil when nothing is saved.
    let savedAt: Date?
}

extension RootView {
    /// A root's line: the replay wins (sending, a failure, signed out); else offline when the monitor says so or the
    /// root's own read failed for the network; else nothing.
    static func statusLine(
        _ inputs: LineInputs, now: Date, calendar: Calendar, openPending: @escaping @MainActor () -> Void
    ) -> StatusLineModel? {
        switch inputs.run {
        case let .sending(count): return .sending(count)
        case let .failed(count): return .failed(count, open: openPending)
        case .signedOut: return .signInAgain
        case .idle:
            guard !inputs.online || inputs.offlineRead else { return nil }
            return .offline(savedAt: inputs.savedAt, now: now, calendar: calendar)
        }
    }

    /// The line for a root showing a copy saved at `savedAt` (nil: nothing saved), whose last read `offlineRead`.
    func statusLine(savedAt: Date?, offlineRead: Bool) -> StatusLineModel? {
        let inputs = LineInputs(
            run: shell.effectiveRun, online: shell.online, offlineRead: offlineRead, savedAt: savedAt
        )
        return Self.statusLine(inputs, now: deps.now(), calendar: DayHeading.india) {
            shell.tabs.push(.pendingChanges)
        }
    }

    /// The centre's queue, made now if the shell has not followed the session yet: the tab roots are built in the same
    /// update that makes the session ready, before `onChange` runs (run 8: the stores got none).
    func centreQueue() -> ChangeQueue? {
        Self.follow(session.state, shell: shell, deps: deps)
        // A change queued while online (behind a waiting one) is sent at once (review I1).
        shell.queue?.onAdded = { Task { await runQueue() } }
        return shell.queue
    }

    /// What a root is told: its line and whether it is offline.
    func rootStatus(savedAt: Date?, offlineRead: Bool) -> RootStatus {
        RootStatus(line: statusLine(savedAt: savedAt, offlineRead: offlineRead), offline: !shell.online || offlineRead)
    }

    /// A list's copy on this iPhone (D39), kept under the centre; the fixtures' copies live in their own folder.
    func cachedRead<Value>(_ workspace: Workspace, _ key: String) -> CachedRead<Value>? {
        guard deps.cachesLists || deps.filesDirectory != nil else { return nil }
        return CachedRead(centre: workspace.centre.id, key: key, directory: deps.filesDirectory)
    }

    /// A month's copy on this iPhone, by month (`<key>-2026-10`).
    func monthCache<Value>(_ workspace: Workspace, _ key: String) -> ((Period) -> CachedRead<Value>)? {
        guard deps.cachesLists || deps.filesDirectory != nil else { return nil }
        let (centre, folder) = (workspace.centre.id, deps.filesDirectory)
        return { CachedRead(centre: centre, key: "\(key)-\($0.isoMonth)", directory: folder) }
    }

    /// Follows the network: the line changes with it, and coming back online sends what waits.
    func followConnectivity() async {
        shell.online = await deps.connectivity.isOnline
        for await online in deps.connectivity.changes() {
            shell.online = online
            if online {
                await runQueue()
            }
        }
    }

    /// Sends what waits, one run at a time (D39): when the network returns, on foreground, after a sign-in, and on
    /// Send again. The toast is AppShell's, shown on whichever screen is open.
    @discardableResult func runQueue() async -> RunOutcome? {
        guard let runner = shell.runner, !runner.running, !runner.queue.pending.inOrder.isEmpty,
              await deps.connectivity.isOnline else { return nil }
        shell.runState = .sending(runner.queue.pending.inOrder.count)
        guard let outcome = await runner.run() else { return nil }
        shell.runState = RunState.after(outcome)
        if let toast = RunState.toast(for: outcome) {
            toasts.show(toast)
        }
        afterRun(outcome)
        return outcome
    }

    /// What a sent change changes elsewhere: the screens read again, only when the run sent or failed something (a run
    /// that stopped offline at once changed nothing, and its read would only fail).
    private func afterRun(_ outcome: RunOutcome) {
        let changed = switch outcome {
        case let .done(sent, failed): sent + failed > 0
        case let .offline(sent), let .signedOut(sent): sent > 0
        }
        if changed {
            afterQueueChanged()
        }
    }

    /// The queue sent or dropped changes: Attendance and Fees read what the server has now (run 9 and run 10: a
    /// sent save still read "saved on this iPhone"; a discarded fee still read paid here).
    func afterQueueChanged() {
        Task { await shell.refreshScreens() }
        replanReminders()
    }
}
