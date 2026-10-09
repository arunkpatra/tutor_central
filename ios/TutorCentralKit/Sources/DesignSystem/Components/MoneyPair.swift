import SwiftUI

/// The money pair hero: Outstanding in `due` over its line, Collected in `ok` over its line, a `line` rule between
/// (components.md, Phase 5 parts; P5-Fees-*, P5-Reports-Fees, P5-StudentFees).
public struct MoneyPair: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let outstanding: String
    let outstandingLine: String
    let collected: String
    let collectedLine: String

    public init(outstanding: String, outstandingLine: String, collected: String, collectedLine: String) {
        self.outstanding = outstanding
        self.outstandingLine = outstandingLine
        self.collected = collected
        self.collectedLine = collectedLine
    }

    public var body: some View {
        Card(.hero) {
            if TypeSizeLayout.stacks(typeSize) {
                // The accessibility sizes: one half over the other, so neither eyebrow breaks a word.
                VStack(spacing: Tokens.rowPaddingHorizontal) {
                    half("Outstanding", outstanding, outstandingLine, tone: .due)
                    Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
                    half("Collected", collected, collectedLine, tone: .ok)
                }
            } else {
                HStack(spacing: 0) {
                    half("Outstanding", outstanding, outstandingLine, tone: .due)
                        .padding(.trailing, Tokens.rowPaddingHorizontal)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(Tokens.line.color).frame(width: Tokens.hairline)
                        }
                    half("Collected", collected, collectedLine, tone: .ok)
                        .padding(.leading, Tokens.rowPaddingHorizontal)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func half(_ eyebrow: String, _ amount: String, _ line: String, tone: StatusTone) -> some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
            Eyebrow(eyebrow)
            Text(amount)
                .typeStyle(Tokens.displayCompact)
                .monospacedDigit()
                .foregroundStyle(tone.color.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MoneyPair(outstanding: "₹4,000", outstandingLine: "4 parents", collected: "₹7,300", collectedLine: "6 of 10 paid")
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
