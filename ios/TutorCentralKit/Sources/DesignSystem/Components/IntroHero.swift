import SwiftUI

/// Intro hero (P6-Scan-Intro, P6-Check-Intro): a hero card (padding 24) with the feature tile 56, the title in
/// emptyTitle and the line in subhead text2, both centred, the line at most 300 wide.
public struct IntroHero: View {
    let symbol: String
    let tint: ColorToken
    let title: String
    let line: String
    static var lineWidth: CGFloat {
        300
    }

    public init(symbol: String, tint: ColorToken = Tokens.text2, title: String, line: String) {
        self.symbol = symbol
        self.tint = tint
        self.title = title
        self.line = line
    }

    public var body: some View {
        VStack(spacing: Tokens.rowPaddingDense) {
            IconTile(symbol: symbol, size: .header, tint: tint)
            VStack(spacing: Tokens.inline) {
                Text(title).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                Text(line)
                    .typeStyle(Tokens.subhead)
                    .foregroundStyle(Tokens.text2.color)
                    .frame(maxWidth: Self.lineWidth)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Tokens.heroInset)
        .surface(radius: Tokens.radiusHero)
        .accessibilityElement(children: .combine)
    }
}

/// Notices card: a list card of rows, each an 18 pt symbol in text2 (lock, checkmark) and its text in rowLine.
public struct NoticesCard: View {
    public struct Notice: Identifiable, Sendable {
        public let symbol: String
        public let text: String
        public var id: String {
            text
        }

        public init(symbol: String, text: String) {
            self.symbol = symbol
            self.text = text
        }
    }

    let notices: [Notice]

    public init(_ notices: [Notice]) {
        self.notices = notices
    }

    public var body: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(notices) { notice in
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.cardPaddingCompact) {
                        Image(systemName: notice.symbol)
                            .font(.system(size: Tokens.iconSmall))
                            .foregroundStyle(Tokens.text2.color)
                            .frame(width: Tokens.iconButton)
                            .accessibilityHidden(true)
                        Text(notice.text)
                            .typeStyle(Tokens.rowLine)
                            .foregroundStyle(Tokens.text2.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, Tokens.cardPaddingCompact)
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .overlay(alignment: .bottom) {
                        if notice.id != notices.last?.id {
                            Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        IntroHero(
            symbol: "doc.viewfinder", title: "Read a paper register",
            line: "Take a photo of a page of your register. We read the names into a list you check."
        )
        NoticesCard([
            .init(symbol: "lock", text: "The photo goes to our AI service to be read and is not kept."),
            .init(symbol: "checkmark", text: "Nothing is saved until you have checked every row and tapped Add."),
        ])
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
