import SwiftUI

/// One ladder area (components.md "Ladder"): the title and the current step's line on the right; five cells, each a
/// 6 pt bar over its name in 11/14: secure `ok`, the current step `accent` with its name in accentText 700, the rest
/// lineStrong and text3.
public struct LadderRow: View {
    public enum Step: Sendable, Equatable {
        case secure, current, later
    }

    let title: String
    let line: String
    let steps: [(name: String, step: Step)]
    static var barHeight: CGFloat {
        6
    }

    static var barRadius: CGFloat {
        3
    }

    static var nameSize: CGFloat {
        11
    }

    public init(title: String, line: String, steps: [(name: String, step: Step)]) {
        self.title = title
        self.line = line
        self.steps = steps
    }

    /// The steps for a count of secure ones: those secure, the next current, the rest to come.
    nonisolated static func stepKinds(secure: Int, of count: Int) -> [Step] {
        (0 ..< count).map { $0 < secure ? .secure : $0 == secure ? .current : .later }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                Spacer(minLength: Tokens.inline)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            HStack(alignment: .top, spacing: Tokens.fieldGap) {
                ForEach(Array(steps.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: Tokens.fieldGap) {
                        RoundedRectangle(cornerRadius: Self.barRadius)
                            .fill(barColor(item.step).color)
                            .frame(height: Self.barHeight)
                        Text(item.name)
                            .font(.system(size: Self.nameSize, weight: item.step == .current ? .bold : .regular))
                            .foregroundStyle(nameColor(item.step).color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }

    private func barColor(_ step: Step) -> ColorToken {
        switch step {
        case .secure: Tokens.ok
        case .current: Tokens.accent
        case .later: Tokens.lineStrong
        }
    }

    private func nameColor(_ step: Step) -> ColorToken {
        switch step {
        case .secure: Tokens.ok
        case .current: Tokens.accentText
        case .later: Tokens.text3
        }
    }
}
