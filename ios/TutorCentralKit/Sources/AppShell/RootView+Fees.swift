import DesignSystem
import Domain
import Fees
import Foundation
import SwiftUI

/// The Fees tab's wiring: its one store, the ways in (the tab, the `fees?month=` link, Today's Due tile), its root and
/// its toasts.
extension RootView {
    /// One fees store for the life of the workspace, so the month and the filter survive a tab switch. A fee write
    /// refreshes the register (the students' month chips, the detail's fee row); That's right updates the workspace.
    func feesStore(for workspace: Workspace) -> FeesStore {
        if let fees = shell.fees {
            return fees
        }
        let made = FeesStore(
            workspace: workspace, register: register(for: workspace), fees: deps.fees, messages: deps.messages,
            centres: deps.centres, now: deps.now
        )
        made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingPayments(from: changed) } }
        made.onFeesChanged = { [shell] in
            Task { await shell.register?.refresh() }
        }
        shell.fees = made
        return made
    }

    /// `tutorcentral://fees?month=YYYY-MM`: the tab at that month (one that does not parse is the current month).
    func openFees(month: Period?, in workspace: Workspace) {
        let store = feesStore(for: workspace)
        shell.tabs.paths[.fees] = []
        shell.tabs.selected = .fees
        Task { await store.open(month: month ?? store.today.period) }
    }

    /// Today's Due tile: the tab at Due.
    func openFeesDue(in workspace: Workspace) {
        let store = feesStore(for: workspace)
        shell.tabs.paths[.fees] = []
        shell.tabs.selected = .fees
        Task { await store.showDue() }
    }

    /// A screen's change, merged onto the session's current workspace with only the fields that screen owns, then
    /// handed to every store that shows the workspace (review: Settings' older copy put back a replaced UPI id).
    func applyWorkspace(_ merge: (Workspace) -> Workspace) {
        guard case let .ready(current) = session.state else { return }
        let merged = merge(current)
        session.workspaceChanged(merged)
        shell.today?.workspaceChanged(merged)
        shell.fees?.workspaceChanged(merged)
        shell.ai?.workspaceChanged(merged)
    }

    /// Remind or Mark paid from the Students tab (the detail, a student's fees): the Fees tab at that month with the
    /// sheet open, as Mark attendance opens on the Attendance tab.
    func openFeeAction(_ action: FeeAction) {
        guard case let .ready(workspace) = session.state else { return }
        let store = feesStore(for: workspace)
        let (studentID, month) = switch action {
        case let .remind(studentID, month), let .markPaid(studentID, month): (studentID, month)
        }
        shell.tabs.paths[.fees] = []
        shell.tabs.selected = .fees
        Task {
            await store.open(month: month)
            guard let invoice = store.invoices.first(where: { $0.studentID == studentID }) else {
                toasts.show("No fee for \(month.monthName) yet. Generate it first.")
                return
            }
            store.sheet = switch action {
            case .remind: .remind(invoice.id)
            case .markPaid: .markPaid(invoice.id)
            }
        }
    }

    /// A student's fees, pushed from the detail's See all.
    @ViewBuilder func studentFeesView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            StudentFeesView(
                store: StudentFeesStore(
                    studentID: id, workspace: workspace, register: register(for: workspace), fees: deps.fees,
                    messages: deps.messages, now: deps.now
                ),
                act: { openFeeAction($0) }
            )
        }
    }

    /// Parent payments, pushed from Settings or from Fees' Payments. A saved id reaches the session, Today and Fees
    /// (whose payee card asks again for a changed id).
    @ViewBuilder var paymentsView: some View {
        if case let .ready(workspace) = session.state {
            PaymentsView(
                store: PaymentsStore(workspace: workspace, centres: deps.centres, qrImages: deps.qrImages),
                boardState: launch.flatMap(Self.paymentsBoardState),
                onWorkspaceChanged: { changed in applyWorkspace { $0.takingPayments(from: changed) } },
                onMessage: { toasts.show($0) }
            )
        }
    }

    /// Reports, pushed from More.
    @ViewBuilder var reportsView: some View {
        if case let .ready(workspace) = session.state {
            ReportsView(
                store: ReportsStore(
                    workspace: workspace, register: register(for: workspace), fees: deps.fees,
                    attendance: deps.attendance, messages: deps.messages, now: deps.now
                ),
                boardState: launch.flatMap(Self.reportsBoardState),
                onMessage: { toasts.show($0) }
            )
        }
    }

    /// "2026-09" → September 2026; nil for anything else.
    nonisolated static func linkMonth(_ text: String?) -> Period? {
        guard let text else { return nil }
        let parts = text.split(separator: "-")
        guard parts.count == 2, parts[0].count == 4, let year = Int(parts[0]), let month = Int(parts[1]),
              (1 ... 12).contains(month) else { return nil }
        return Period(year: year, month: month)
    }

    @ViewBuilder var feesView: some View {
        if case let .ready(workspace) = session.state {
            let store = feesStore(for: workspace)
            FeesView(
                store: store,
                actions: FeesActions(openPayments: { shell.tabs.push(.payments) }),
                boardState: launch.flatMap(Self.feesBoardState)
            )
            .onChange(of: store.undo) { _, undo in
                guard let undo else { return }
                toasts.show(undo.text, action: ("Undo", { Task { _ = await store.undoPaid(undo.invoiceID) } }))
                store.undo = nil
            }
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                Haptic.play(store.canRetry ? .error : .success)
                toasts.show(message, action: store.canRetry ? Self.retry(store) : nil)
                store.message = nil
            }
            .onChange(of: store.lastSavedAt) { Haptic.play(.success) }
        }
    }
}
