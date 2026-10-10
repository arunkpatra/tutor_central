import SwiftUI

/// The checks' three weeks (components.md "Trend card"): the title and the percentage, a bar per session (36 high,
/// radius 3, 4 apart, on lineStrong tracks) filled to its right answers of three, `ok` 3, `due` 2, `overdue` fewer; a
/// footnote line.
public struct TrendCard: View {
    let title: String
    let percent: String
    let right: [Int]
    let line: String
    static var barHeight: CGFloat {
        36
    }

    static var barRadius: CGFloat {
        3
    }

    static var barGap: CGFloat {
        4
    }

    public init(title: String, percent: String, right: [Int], line: String) {
        self.title = title
        self.percent = percent
        self.right = right
        self.line = line
    }

    /// The share of a session's three questions answered right.
    nonisolated static func fraction(right: Int) -> Double {
        Double(min(max(right, 0), 3)) / 3
    }

    nonisolated static func tone(right: Int) -> StatusTone {
        switch right {
        case 3...: .ok
        case 2: .due
        default: .overdue
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            HStack {
                Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                Spacer()
                Text(percent).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
            }
            HStack(alignment: .bottom, spacing: Self.barGap) {
                ForEach(Array(right.enumerated()), id: \.offset) { _, value in
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: Self.barRadius).fill(Tokens.lineStrong.color)
                        RoundedRectangle(cornerRadius: Self.barRadius)
                            .fill(Self.tone(right: value).color.color)
                            .frame(height: Self.barHeight * Self.fraction(right: value))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.barHeight)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(right.map { "\($0) of 3" }.joined(separator: ", "))
            Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
        }
        .padding(Tokens.rowPaddingHorizontal)
        .surface(radius: Tokens.radiusCard)
    }
}
