import SwiftUI

/// The tracking card (components.md "Tracking card"): a compact hero, padding 16, radius 18; the status word 17/700
/// with
/// its symbol 20 and "since <day>" caption text3 on the right; the reasons rowLine text2; a line rule; the eyebrow
/// "Next"
/// over the step in rowLine text, a quiet action on the right (Place <name>) when there is one.
public struct TrackingCard: View {
    let word: String
    let kind: TrackKind
    let since: String?
    let reasons: String
    let next: String
    let action: (label: String, run: () -> Void)?
    static var symbolSize: CGFloat {
        20
    }

    public init(
        word: String, kind: TrackKind, since: String?, reasons: String, next: String,
        action: (label: String, run: () -> Void)? = nil
    ) {
        self.word = word
        self.kind = kind
        self.since = since
        self.reasons = reasons
        self.next = next
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
                Label {
                    Text(word).typeStyle(Tokens.headline)
                } icon: {
                    Image(systemName: kind.symbol).font(.system(size: Self.symbolSize, weight: .semibold))
                }
                .labelStyle(InlineLabelStyle())
                .foregroundStyle(kind.color.color)
                Spacer(minLength: Tokens.inline)
                if let since {
                    Text(since).typeStyle(Tokens.caption).foregroundStyle(Tokens.text3.color)
                }
            }
            Text(reasons)
                .typeStyle(Tokens.rowLine)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
            HStack(alignment: .top, spacing: Tokens.inline) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Eyebrow("Next")
                    Text(next)
                        .typeStyle(Tokens.rowLine)
                        .foregroundStyle(Tokens.text.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let action {
                    Button(action.label, action: action.run).buttonStyle(.quiet).fixedSize()
                }
            }
        }
        .padding(Tokens.rowPaddingHorizontal)
        .surface(radius: Tokens.radiusCard)
    }
}
