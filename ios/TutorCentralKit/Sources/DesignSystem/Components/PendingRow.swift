import SwiftUI

/// A change kept on this iPhone (P7-Pending): an icon tile 40, the title in rowTitle, the line with its state first in
/// 600 ("Waiting" text3, "Failed" overdue) then what and when; a failed row adds its reason in overdue and a quiet
/// Discard. Padding 12 16; the reason sits 52 in, under the title.
public struct PendingRow: View {
    let symbol: String
    let title: String
    let line: String
    let failure: String?
    let discard: () -> Void
    static var reasonInset: CGFloat {
        52
    }

    /// `failure` is the reason a failed change carries; nil while it waits.
    public init(symbol: String, title: String, line: String, failure: String?, discard: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.failure = failure
        self.discard = discard
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            HStack(spacing: Tokens.rowPaddingDense) {
                IconTile(symbol: symbol)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    (Text(failure == nil ? "Waiting" : "Failed")
                        .foregroundStyle((failure == nil ? Tokens.text3 : Tokens.overdue).color)
                        .fontWeight(.semibold)
                        + Text(" · \(line)").foregroundStyle(Tokens.text2.color))
                        .typeStyle(Tokens.footnote)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            if let failure {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.rowPaddingDense) {
                    Text(failure)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.overdue.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Discard", action: discard).buttonStyle(.quiet(tone: .overdue))
                }
                .padding(.leading, Self.reasonInset)
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            PendingRow(
                symbol: "checkmark.circle", title: "Attendance · Class 10 Maths",
                line: "Wed 7 Oct · 5 of 6 present · 17:05", failure: nil
            ) {}
                .rowDivider()
            PendingRow(
                symbol: "indianrupeesign", title: "Fee · Dev Kumar", line: "₹1,000 by UPI on 7 Oct · 17:12",
                failure: "Dev Kumar is no longer in the register, so their fee can't be marked."
            ) {}
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
