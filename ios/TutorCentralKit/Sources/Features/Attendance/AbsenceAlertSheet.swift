import DesignSystem
import Domain
import SwiftUI

/// The absence alert (P4-Absence-Alert; components.md, Message sheet): a floating sheet (D28) with Cancel and no Save,
/// the student and parent, the message in a well, what happens, and Open WhatsApp, which logs the alert first (D3).
struct AbsenceAlertSheet: View {
    let alert: AbsenceAlert
    let open: () async -> Void
    let close: () -> Void
    @State private var opening = false
    /// The board's sheet starts 300 pt down an 852 pt screen.
    static var boardFraction: CGFloat {
        0.65
    }

    static var avatarSize: CGFloat {
        56
    }

    private var note: String {
        "Opens WhatsApp with the message ready to send. We note the date in \(alert.student.firstName)'s record."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Tell the parent", cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                HStack(spacing: Tokens.cardPaddingCompact) {
                    Avatar(name: alert.student.name, size: Self.avatarSize)
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(alert.headline).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                        Text(alert.parentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                }
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Text("Message").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    Text(alert.text)
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
                Text(note)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
            }
            Spacer(minLength: 0)
            Button {
                Task {
                    opening = true
                    await open()
                    opening = false
                }
            } label: {
                Label("Open WhatsApp", systemImage: "message")
            }
            .buttonStyle(.primary(.sheet, loading: opening))
            .disabled(alert.url == nil)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .modifier(SheetToasts())
        .presentationDetents([.fraction(Self.boardFraction), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}
