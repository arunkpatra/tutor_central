import Attendance
import DesignSystem
import Domain
import Foundation
import SwiftUI

/// The Attendance tab's wiring: its one store, the ways in (the tab, Mark attendance, the link) and its root.
extension RootView {
    /// One mark screen for the life of the workspace, so the date, the class and the unsaved toggles survive a tab
    /// switch. It reads the shared register.
    func attendanceStore(for workspace: Workspace) -> AttendanceStore {
        if let attendance = shell.attendance {
            return attendance
        }
        let made = AttendanceStore(
            workspace: workspace,
            register: register(for: workspace),
            attendance: deps.attendance,
            messages: deps.messages,
            now: deps.now
        )
        made.cache = monthCache(workspace, "attendance")
        made.queue = centreQueue()
        made.online = { [connectivity = deps.connectivity] in await connectivity.isOnline }
        shell.attendance = made
        return made
    }

    /// Mark attendance on a class, on Today, or the `attendance?date=&class=` link: the tab, at that class and day (a
    /// day that does not parse is today).
    func openAttendance(classID: UUID?, date: Day?, in workspace: Workspace) {
        let store = attendanceStore(for: workspace)
        shell.tabs.paths[.attendance] = []
        shell.tabs.selected = .attendance
        Task { await store.open(classID: classID, date: date ?? store.today) }
    }

    /// History, pushed on the Attendance tab; a class opens on the mark root at its day.
    @ViewBuilder var historyView: some View {
        if case let .ready(workspace) = session.state {
            HistoryView(
                store: HistoryStore(
                    workspace: workspace, register: register(for: workspace), attendance: deps.attendance,
                    now: deps.now, cache: monthCache(workspace, "history")
                ),
                openSession: { openAttendance(classID: $0.classID, date: $0.date, in: workspace) },
                openStudent: { shell.tabs.push(.historyStudent($0)) },
                boardState: launch.flatMap(Self.historyBoardState),
                status: { rootStatus(savedAt: $0, offlineRead: $1) }
            )
        }
    }

    /// A student's month, from History or from the student detail's See all.
    @ViewBuilder func studentMonthView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            StudentMonthView(
                store: StudentMonthStore(
                    studentID: id, workspace: workspace, register: register(for: workspace),
                    attendance: deps.attendance, messages: deps.messages, now: deps.now
                ),
                openSession: { openAttendance(classID: $0.classID, date: $0.date, in: workspace) }
            )
        }
    }

    @ViewBuilder var attendanceView: some View {
        if case let .ready(workspace) = session.state {
            let store = attendanceStore(for: workspace)
            AttendanceView(
                store: store,
                actions: AttendanceActions(
                    openStudents: { shell.tabs.select(.students) },
                    openHistory: { shell.tabs.push(.history) }
                ),
                boardState: launch.flatMap(Self.attendanceBoardState)
                    ?? (launch == .offlineAttendanceSaved ? .saved : nil),
                status: rootStatus(savedAt: store.savedAt, offlineRead: store.offlineRead)
            )
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                Haptic.play(.error)
                notices.show(message, retry: store.canRetry ? Self.retry(store) : nil)
                store.message = nil
            }
        }
    }
}
