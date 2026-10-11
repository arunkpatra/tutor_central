import SwiftUI

/// A mark read from a photo (P14-Marks-Confirm): the tick (filled `ok` when it will be saved, a ring when not), the
/// subject and test, the date or "Date · not given" in `text3`, the score, the chevron. The tick toggles; the rest
/// opens
/// the mark's sheet.
public struct MarkReadRow: View {
    let title: String
    let line: String
    let lineIsMissing: Bool
    let score: String
    let ticked: Bool
    let toggle: () -> Void
    let open: () -> Void
    static var tickSize: CGFloat {
        22
    }

    public init(
        title: String, line: String, lineIsMissing: Bool, score: String, ticked: Bool,
        toggle: @escaping () -> Void, open: @escaping () -> Void
    ) {
        self.title = title
        self.line = line
        self.lineIsMissing = lineIsMissing
        self.score = score
        self.ticked = ticked
        self.toggle = toggle
        self.open = open
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Button(action: toggle) { tick }
                .buttonStyle(.plain)
                .accessibilityLabel(ticked ? "Will be saved" : "Will not be saved")
                .accessibilityAddTraits(ticked ? .isSelected : [])
            Button(action: open) {
                HStack(spacing: Tokens.rowPaddingDense) {
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(line).typeStyle(Tokens.footnote)
                            .foregroundStyle((lineIsMissing ? Tokens.text3 : Tokens.text2).color)
                    }
                    Spacer(minLength: Tokens.inline)
                    Text(score).typeStyle(Tokens.numberRow).monospacedDigit().foregroundStyle(Tokens.text.color)
                    Chevron()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .pressable()
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
    }

    @ViewBuilder private var tick: some View {
        if ticked {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .symbolRenderingMode(.palette)
                .foregroundStyle(Tokens.surface1.color, Tokens.ok.color)
                .frame(width: Self.tickSize, height: Self.tickSize)
        } else {
            Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline * 1.5)
                .frame(width: Self.tickSize, height: Self.tickSize)
        }
    }
}
