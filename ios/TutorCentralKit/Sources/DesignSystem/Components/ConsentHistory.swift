import SwiftUI

/// One event of a student's consent history: "Withdrew · on a call" with its day, "Mon 12 Oct".
public struct ConsentHistoryLine: Hashable, Sendable, Identifiable {
    public let what: String
    public let day: String

    public var id: String {
        "\(what)|\(day)"
    }

    public init(what: String, day: String) {
        self.what = what
        self.day = day
    }
}

/// The consent row's history (P18-Student-Withdrawn): the HISTORY eyebrow, then one line per event, newest first, the
/// day on the right.
public struct ConsentHistory: View {
    let lines: [ConsentHistoryLine]

    public init(lines: [ConsentHistoryLine]) {
        self.lines = lines
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Eyebrow("History")
            ForEach(lines) { line in
                AdaptiveRow(spacing: Tokens.rowPaddingDense) {
                    Text(line.what)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                    AdaptiveSpacer()
                    Text(line.day)
                        .typeStyle(Tokens.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Tokens.text3.color)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
