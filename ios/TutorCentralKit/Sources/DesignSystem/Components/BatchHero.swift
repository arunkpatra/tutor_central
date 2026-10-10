import SwiftUI

/// The batch hero (components.md 10.3, the Kit's next-class hero): the eyebrow (accentText while the batch is soon or
/// running, or on a day with none), the batch in title2, its line in subhead; Start class (primary, `play`) while it
/// can
/// start; closed, the title carries `checkmark.circle` in `ok` and Open the class is the secondary button.
public struct BatchHero: View {
    public enum Action {
        case primary(String, symbol: String, run: () -> Void)
        case secondary(String, run: () -> Void)
    }

    let eyebrow: String
    let accent: Bool
    let title: String
    let titleMark: Bool
    let line: String
    let action: Action?

    public init(eyebrow: String, accent: Bool, title: String, titleMark: Bool, line: String, action: Action?) {
        self.eyebrow = eyebrow
        self.accent = accent
        self.title = title
        self.titleMark = titleMark
        self.line = line
        self.action = action
    }

    public var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                Eyebrow(eyebrow, accent: accent, strong: accent)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    HStack(spacing: Tokens.inline) {
                        if titleMark {
                            Image(systemName: "checkmark.circle")
                                .typeStyle(Tokens.title2)
                                .foregroundStyle(Tokens.ok.color)
                                .accessibilityHidden(true)
                        }
                        Text(title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                    }
                    Text(line).typeStyle(Tokens.subhead).monospacedDigit().foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                switch action {
                case let .primary(label, symbol, run):
                    Button(action: run) {
                        Label(label, systemImage: symbol)
                            .typeStyle(Tokens.buttonStrong)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary(.card))
                    .padding(.top, Tokens.rowGapInner)
                case let .secondary(label, run):
                    Button(action: run) { Text(label).frame(maxWidth: .infinity) }
                        .buttonStyle(.secondary())
                        .padding(.top, Tokens.rowGapInner)
                case nil:
                    EmptyView()
                }
            }
        }
    }
}
