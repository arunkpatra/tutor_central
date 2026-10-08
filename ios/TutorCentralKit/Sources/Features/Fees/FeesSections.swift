import DesignSystem
import Domain
import SwiftUI

/// The payee card (P5-Fees-Payee) until the UPI id is confirmed once, or "No UPI id yet" with Add (P5-Fees-Empty).
struct PayeeSection: View {
    let store: FeesStore
    let actions: FeesActions

    var body: some View {
        switch store.payee {
        case let .confirm(upiID):
            PayeeCard(
                title: "Parents are told to pay \(upiID)", line: "Reminders carry this UPI id. Not right? Change it.",
                change: actions.openPayments, confirm: { Task { await store.confirmPayee() } },
                confirming: store.confirming
            )
        case .add:
            Card {
                HStack(spacing: 0) {
                    EmptyRow(
                        symbol: "indianrupeesign", title: "No UPI id yet",
                        line: "Reminders tell parents where to pay. Add your UPI id or scan its QR."
                    )
                    Button("Add", action: actions.openPayments)
                        .buttonStyle(.quiet)
                        .padding(.trailing, Tokens.rowPaddingHorizontal)
                }
            }
        case nil:
            EmptyView()
        }
    }
}

/// A month with no fees yet (P5-Fees-Empty): the one card with Generate.
struct EmptyMonthCard: View {
    let month: Period
    let generate: () -> Void

    var body: some View {
        Card {
            EmptyState(
                symbol: "indianrupeesign", title: "No fees for \(month.monthName) yet",
                line: "Generate them to see who owes what: one fee per student, from the class fee or their own.",
                action: .init("Generate \(month.monthName)'s fees", emphasis: .primary, run: generate),
                size: .screen
            )
        }
    }
}

/// The month's fees: the money pair, the payee card, the overdue banner, All | Due | Paid, the ledger.
struct LedgerSections: View {
    @Bindable var store: FeesStore
    let actions: FeesActions

    var body: some View {
        MoneyPair(
            outstanding: store.totals.outstanding.formatted, outstandingLine: store.outstandingLine,
            collected: store.totals.collected.formatted, collectedLine: store.totals.collectedLine
        )
        PayeeSection(store: store, actions: actions)
        if let overdue = store.overdue {
            BannerLink(symbol: "exclamationmark.circle", text: overdue.text, tone: .overdue) {
                Task { await store.openOverdue() }
            }
        }
        Segmented(options: FeeFilter.allCases.map { ($0, $0.title) }, selection: $store.filter)
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.ledgerTitle, action: generateAction)
            if store.rows.isEmpty {
                Card { emptyFilter }
            } else {
                Card {
                    VStack(spacing: 0) {
                        ForEach(store.rows) { row in
                            FeeRow(
                                title: row.name, line: FeeRowLine(row.line, tone: row.lineTone, symbol: row.lineSymbol),
                                amount: row.invoice.amount.formatted, chip: Self.chip(row.state),
                                buttons: row.showsButtons ? buttons(row.id) : nil
                            )
                            .rowDivider(row.id != store.rows.last?.id)
                        }
                    }
                }
            }
        }
    }

    private var generateAction: (label: String, run: () -> Void) {
        ("Generate", { store.sheet = .generate })
    }

    private func buttons(_ id: UUID) -> FeeButtons {
        FeeButtons(remind: { store.sheet = .remind(id) }, markPaid: { store.sheet = .markPaid(id) })
    }

    /// Nothing under a filter: the Kit's empty row in the board's words.
    @ViewBuilder private var emptyFilter: some View {
        if store.filter == .paid {
            EmptyRow(symbol: "checkmark.circle", title: "Nothing paid yet", line: "Fees you mark paid appear here.")
        } else {
            EmptyRow(
                symbol: "checkmark.circle", title: "Nothing due",
                line: "Every fee for \(store.month.monthName) is settled."
            )
        }
    }

    /// The compact chip of a fee's state (components.md, Fee row).
    nonisolated static func chip(_ state: FeeState) -> Chip.Kind {
        switch state {
        case .due: .status(.due, "Due", symbol: "clock")
        case .overdue: .status(.overdue, "Overdue", symbol: "exclamationmark.circle")
        case .paid: .status(.ok, "Paid", symbol: "checkmark")
        case .waived: .neutral("Waived")
        }
    }
}

/// A read that failed: what happened and Retry (Today's error line).
struct FeesErrorLine: View {
    let error: String
    let retry: () -> Void

    init(_ error: String, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    var body: some View {
        HStack {
            Label(error, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry", action: retry).buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}
