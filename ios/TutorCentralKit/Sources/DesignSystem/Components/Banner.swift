import SwiftUI

/// One line of state under a header (a student's "Archived: …"): surface2, radius 12, padding 8 14, footnote text2
/// with a symbol 14; the offline bar's pattern. A banner that says something went well takes its status colour (the
/// attendance mark's "Saved at 18:32", P4-Attendance-Mark-Saved).
public struct Banner: View {
    let symbol: String
    let text: String
    let tone: StatusTone?
    static var radius: CGFloat {
        12
    }

    static var symbolSize: CGFloat {
        14
    }

    public init(symbol: String, text: String, tone: StatusTone? = nil) {
        self.symbol = symbol
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
            Image(systemName: symbol).font(.system(size: Self.symbolSize)).accessibilityHidden(true)
            Text(text).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .typeStyle(Tokens.footnote)
        .foregroundStyle((tone?.color ?? Tokens.text2).color)
        .padding(.vertical, Tokens.inline)
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .background(Tokens.surface2.color, in: .rect(cornerRadius: Self.radius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A Banner that opens something (the overdue banner on Fees, P5-Fees-All): the chevron on the right, the whole line
/// presses; the tone colours the words and the symbol, the chevron is text3.
public struct BannerLink: View {
    let symbol: String
    let text: String
    let tone: StatusTone?
    let action: () -> Void

    public init(symbol: String, text: String, tone: StatusTone?, action: @escaping () -> Void) {
        self.symbol = symbol
        self.text = text
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Tokens.inline) {
                Image(systemName: symbol).font(.system(size: Banner.symbolSize)).accessibilityHidden(true)
                Text(text).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Chevron()
            }
            .typeStyle(Tokens.footnote)
            .foregroundStyle((tone?.color ?? Tokens.text2).color)
            .padding(.vertical, Tokens.inline)
            .padding(.horizontal, Tokens.cardPaddingCompact)
            .background(Tokens.surface2.color, in: .rect(cornerRadius: Banner.radius, style: .continuous))
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    BannerLink(symbol: "exclamationmark.circle", text: "₹1,000 overdue from September · 1 parent", tone: .overdue) {}
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}

#Preview {
    Banner(symbol: "archivebox", text: "Archived: off the list and today's counts. Their fees and attendance stay.")
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
