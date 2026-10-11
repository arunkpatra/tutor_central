import SwiftUI

/// The held sheet (P10-Held; components.md 10.6): Cancel and "Held", the avatar with "Held for this week" and the
/// parent,
/// an on-sheet card of the parent's suggested messages this week (an icon by kind, the kind, the day), the footnote,
/// and
/// two buttons: Send it now (secondary) and Keep it for next week (primary).
public struct HeldSheet: View {
    public struct Message: Hashable, Sendable {
        let symbol: String
        let kind: String
        let day: String

        public init(symbol: String, kind: String, day: String) {
            self.symbol = symbol
            self.kind = kind
            self.day = day
        }
    }

    public static let sheetTitle = "Held"
    public static let heading = "Held for this week"
    public static let sendNow = "Send it now"
    public static let keep = "Keep it for next week"
    /// The board's sheet starts 250 pt down an 852 pt screen.
    public static var boardFraction: CGFloat {
        0.71
    }

    let initials: String
    let parentLine: String
    let messages: [Message]
    let footnote: String
    let send: () -> Void
    let close: () -> Void

    public init(
        initials: String, parentLine: String, messages: [Message], footnote: String, send: @escaping () -> Void,
        close: @escaping () -> Void
    ) {
        self.initials = initials
        self.parentLine = parentLine
        self.messages = messages
        self.footnote = footnote
        self.send = send
        self.close = close
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: Self.sheetTitle, cancel: ("Cancel", close))
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                    HStack(spacing: Tokens.cardPaddingCompact) {
                        Avatar(initials: initials, size: MessageSheet.avatarSize)
                        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                            Text(Self.heading).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                            Text(parentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Card(.onSheet) {
                        VStack(spacing: 0) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                ListRow(action: nil) {
                                    Image(systemName: message.symbol)
                                        .typeStyle(Tokens.body)
                                        .foregroundStyle(Tokens.text2.color)
                                        .frame(width: IconTile.rowSize)
                                        .accessibilityHidden(true)
                                    RowTitles(title: message.kind, subtitle: message.day)
                                }
                                .rowDivider(index < messages.count - 1)
                            }
                        }
                    }
                    Text(footnote)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            HStack(spacing: Tokens.tileGap) {
                Button(Self.sendNow, action: send).buttonStyle(.secondary(.sheet))
                Button(Self.keep, action: close).buttonStyle(.primary(.sheet))
            }
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .presentationDetents([.fraction(Self.boardFraction), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}
