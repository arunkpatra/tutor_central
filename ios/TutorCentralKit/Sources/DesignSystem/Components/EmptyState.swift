import SwiftUI

/// Inside the card it belongs to: symbol 28 in text3, title headline, one line subhead text2 (at most 280 wide), and
/// when there is an action a secondary button (primary when it is the only thing to do). Centred, padding 24 18.
public struct EmptyState: View {
    public enum Emphasis: Sendable {
        case secondary
        case primary
    }

    /// The button under the line.
    public struct Action {
        let label: String
        let emphasis: Emphasis
        let run: () -> Void

        public init(_ label: String, emphasis: Emphasis = .secondary, run: @escaping () -> Void) {
            self.label = label
            self.emphasis = emphasis
            self.run = run
        }
    }

    let symbol: String
    let title: String
    let line: String
    let action: Action?
    static var symbolSize: CGFloat {
        28
    }

    public init(
        symbol: String,
        title: String,
        line: String,
        action: Action? = nil
    ) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.action = action
    }

    public var body: some View {
        VStack(spacing: Tokens.fieldGap) {
            Image(systemName: symbol).font(.system(size: Self.symbolSize)).foregroundStyle(Tokens.text3.color)
            Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color).padding(
                .top,
                Tokens.rowGapInner * 2
            )
            Text(line)
                .typeStyle(Tokens.subhead)
                .foregroundStyle(Tokens.text2.color)
                .frame(maxWidth: Tokens.measureLine)
            if let action {
                Group {
                    if action.emphasis == .primary {
                        Button(action.label, action: action.run).buttonStyle(.primary())
                    } else {
                        Button(action.label, action: action.run).buttonStyle(.secondary())
                    }
                }
                .fixedSize()
                .padding(.top, Tokens.inline)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Tokens.heroInset)
        .padding(.horizontal, Tokens.cardPadding)
    }
}
