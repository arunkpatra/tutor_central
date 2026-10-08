import SwiftUI

/// Inside the card it belongs to: symbol 28 in text3, title headline, one line subhead text2 (at most 280 wide), and
/// when there is an action a secondary button (primary when it is the only thing to do); two actions sit side by side
/// at equal widths, 10 apart (P3-Students-Empty). Centred, padding 24 18.
public struct EmptyState: View {
    /// `card` sits among other sections; `screen` is the one card of a root with nothing else to show
    /// (P4-Attendance-Empty): padding 40 24, its button 220 wide.
    public enum Size: Sendable {
        case card
        case screen
    }

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
    let actions: [Action]
    let size: Size
    static var symbolSize: CGFloat {
        28
    }

    static var screenButtonWidth: CGFloat {
        220
    }

    public init(
        symbol: String,
        title: String,
        line: String,
        action: Action? = nil,
        size: Size = .card
    ) {
        self.symbol = symbol
        self.title = title
        self.line = line
        actions = action.map { [$0] } ?? []
        self.size = size
    }

    /// Two ways to start, side by side: the first is usually the primary.
    public init(symbol: String, title: String, line: String, actions: (Action, Action)) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.actions = [actions.0, actions.1]
        size = .card
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
            if actions.count == 1, size == .screen {
                button(actions[0], fills: true).frame(maxWidth: Self.screenButtonWidth).padding(.top, Tokens.inline)
            } else if actions.count == 1 {
                button(actions[0]).fixedSize().padding(.top, Tokens.inline)
            } else if !actions.isEmpty {
                HStack(spacing: Tokens.tileGap) {
                    ForEach(actions.indices, id: \.self) { index in
                        button(actions[index], fills: true)
                    }
                }
                .padding(.top, Tokens.inline)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, size == .screen ? Tokens.emptyPadding : Tokens.heroInset)
        .padding(.horizontal, size == .screen ? Tokens.heroInset : Tokens.cardPadding)
    }

    @ViewBuilder private func button(_ action: Action, fills: Bool = false) -> some View {
        if action.emphasis == .primary {
            Button(action: action.run) {
                // Side by side the board sets the primary at 15 700, its pair's size (P3-Students-Empty).
                Text(action.label).typeStyle(fills ? Tokens.buttonStrong : Tokens.button)
                    .frame(maxWidth: fills ? .infinity : nil)
            }
            .buttonStyle(.primary())
        } else {
            Button(action: action.run) { Text(action.label).frame(maxWidth: fills ? .infinity : nil) }
                .buttonStyle(.secondary())
        }
    }
}
