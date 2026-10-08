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

#Preview {
    Banner(symbol: "archivebox", text: "Archived: off the list and today's counts. Their fees and attendance stay.")
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
