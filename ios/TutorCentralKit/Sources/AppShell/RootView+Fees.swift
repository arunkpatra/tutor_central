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
        made.onWorkspaceChanged = { [session, shell] changed in
            session.workspaceChanged(changed)
            shell.today?.workspaceChanged(changed)
        }
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
        feesStore(for: workspace).filter = .due
        shell.tabs.select(.fees)
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
                actions: FeesActions(openPayments: { shell.tabs.push(.later(.payments)) }),
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
