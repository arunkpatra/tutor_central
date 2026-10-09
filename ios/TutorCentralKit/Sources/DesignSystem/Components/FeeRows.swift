import SwiftUI

/// The second line of a fee row: its words, an optional tone (`ok` for "Reminded Tue 6 Oct") and symbol (a tick).
public struct FeeRowLine: Hashable, Sendable {
    /// The tick beside "Reminded …": 14, the Banner's symbol size (P5-Fees-All).
    static var symbolSize: CGFloat {
        14
    }

    public let text: String
    public let tone: StatusTone?
    public let symbol: String?

    public init(_ text: String, tone: StatusTone? = nil, symbol: String? = nil) {
        self.text = text
        self.tone = tone
        self.symbol = symbol
    }
}

/// Remind (secondary, bell) and Mark paid (primary, checkmark), 44 high, radius 14, side by side (the Kit's fee row);
/// without `remind`, Mark paid alone across the row (a waived month on a student's fees, the owner's call).
public struct FeeButtons: View {
    let remind: (() -> Void)?
    let remindEnabled: Bool
    let markPaid: () -> Void

    /// `remindEnabled` false dims Remind (offline: a reminder is noted on the fee, which needs the server).
    public init(remind: (() -> Void)?, remindEnabled: Bool = true, markPaid: @escaping () -> Void) {
        self.remind = remind
        self.remindEnabled = remindEnabled
        self.markPaid = markPaid
    }

    public var body: some View {
        HStack(spacing: Tokens.tileGap) {
            if let remind {
                Button(action: remind) {
                    Label("Remind", systemImage: "bell")
                }
                .buttonStyle(.secondary(.row))
                .disabled(!remindEnabled)
            }
            Button(action: markPaid) {
                Label("Mark paid", systemImage: "checkmark")
            }
            .buttonStyle(.primary(.row))
        }
        .environment(\.buttonIconSize, Tokens.iconSmall)
    }
}

/// The fee row (components.md, Fee row): the title `rowTitle` over its line; on the right the amount `numberRow` over
/// a compact chip; the buttons under them on a due row. Padding 12 16; the row itself does not press.
public struct FeeRow: View {
    let title: String
    let line: FeeRowLine
    let amount: String
    let chip: Chip.Kind
    let buttons: FeeButtons?

    public init(title: String, line: FeeRowLine, amount: String, chip: Chip.Kind, buttons: FeeButtons? = nil) {
        self.title = title
        self.line = line
        self.amount = amount
        self.chip = chip
        self.buttons = buttons
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    lineView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: Tokens.rowGapInner * 2) {
                    Text(amount).typeStyle(Tokens.numberRow).monospacedDigit().foregroundStyle(Tokens.text.color)
                    Chip(chip, compact: true)
                }
                .fixedSize()
            }
            .accessibilityElement(children: .combine)
            if let buttons {
                buttons
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var lineView: some View {
        HStack(spacing: Tokens.rowGapInner * 2) {
            if let symbol = line.symbol {
                Image(systemName: symbol)
                    .font(.system(size: FeeRowLine.symbolSize, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(line.text)
        }
        .typeStyle(Tokens.footnote)
        .monospacedDigit()
        .foregroundStyle((line.tone?.color ?? Tokens.text2).color)
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            FeeRow(
                title: "Dev Kumar", line: FeeRowLine("Reminded Tue 6 Oct", tone: .ok, symbol: "checkmark"),
                amount: "₹1,000", chip: .status(.due, "Due", symbol: "clock"),
                buttons: FeeButtons(remind: {}, markPaid: {})
            )
            .rowDivider()
            FeeRow(
                title: "Hemanth Reddy", line: FeeRowLine("Lakshmi Reddy · +91 93802 60871"), amount: "₹1,200",
                chip: .status(.due, "Due", symbol: "clock"), buttons: FeeButtons(remind: {}, markPaid: {})
            )
            .rowDivider()
            FeeRow(
                title: "Akshita Rao", line: FeeRowLine("Paid by UPI on 4 Oct"), amount: "₹1,200",
                chip: .status(.ok, "Paid", symbol: "checkmark")
            )
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
