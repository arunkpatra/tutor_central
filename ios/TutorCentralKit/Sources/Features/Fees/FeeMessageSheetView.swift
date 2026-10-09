import DesignSystem
import SwiftUI

/// P5-Remind and P5-Receipt: the absence alert's sheet with the fee's words; Open WhatsApp logs first, then opens the
/// link (the reminder's text is copied too).
struct FeeMessageSheetView: View {
    let message: FeeMessageSheet
    let fraction: Double
    let send: (FeeMessageSheet) async -> Void
    let close: () -> Void
    @State private var opening = false
    /// The boards' sheets start 248 pt (Remind) and 290 pt (Receipt) down an 852 pt screen.
    static let remindFraction = 0.71
    static let receiptFraction = 0.66

    static var avatarSize: CGFloat {
        56
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: message.title, cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                HStack(spacing: Tokens.cardPaddingCompact) {
                    Avatar(name: message.student.name, size: Self.avatarSize)
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(message.headline).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                        Text(message.parentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Text(message.label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    Text(message.text)
                        .typeStyle(Tokens.body)
                        .foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Tokens.cardPaddingCompact)
                        .background(
                            Tokens.well.color,
                            in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                                .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
                        )
                        .shadowed(Tokens.shadowWell, radius: Tokens.radiusControl)
                        .textSelection(.enabled)
                }
                Text(message.note).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
            Spacer(minLength: 0)
            Button {
                Task {
                    opening = true
                    await send(message)
                    opening = false
                }
            } label: {
                Label("Open WhatsApp", systemImage: "message")
            }
            .buttonStyle(.primary(.sheet, loading: opening))
            .disabled(message.url == nil || opening)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .boardDetents(fraction)
    }
}
