import SwiftUI

/// The message sheet (components.md, Message sheet; P6-ProgressNote-Send): a floating sheet (D28) with Cancel and no
/// Save, the student (avatar 56, name, the parent and their number), the message in a well, what happens, and Open
/// WhatsApp (loading while `open` runs: it logs first, D3). A parent without a number: the button is disabled and the
/// note says so. Attendance and Fees keep their own copies of this body for now.
public struct MessageSheet: View {
    let title: String
    let name: String
    let parentLine: String
    let text: String
    let note: String
    let canOpen: Bool
    let open: () async -> Void
    let close: () -> Void
    @State private var opening = false
    static var avatarSize: CGFloat {
        56
    }

    /// The board's sheet starts 100 pt down an 852 pt screen.
    public static var boardFraction: CGFloat {
        0.88
    }

    public init(
        title: String, name: String, parentLine: String, text: String, note: String, canOpen: Bool,
        open: @escaping () async -> Void, close: @escaping () -> Void
    ) {
        self.title = title
        self.name = name
        self.parentLine = parentLine
        self.text = text
        self.note = note
        self.canOpen = canOpen
        self.open = open
        self.close = close
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: title, cancel: ("Cancel", close))
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                    HStack(spacing: Tokens.cardPaddingCompact) {
                        Avatar(name: name, size: Self.avatarSize)
                        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                            Text(name).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                            Text(parentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                        Text("Message").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                        Text(text)
                            .typeStyle(Tokens.body)
                            .foregroundStyle(Tokens.text.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Tokens.cardPaddingCompact)
                            .background(
                                Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                                    .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
                            )
                            .shadowed(Tokens.shadowWell, radius: Tokens.radiusControl)
                            .textSelection(.enabled)
                    }
                    Text(note).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
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
            .disabled(!canOpen)
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

/// The consent sheet (P6-Scan-Consent; components.md, Consent sheet): Cancel and "Before the first photo", the text,
/// the
/// footnote with the centre's name, and "I agree, continue" (loading while the agreement is written). Shown before the
/// first photo or the first progress note of a centre, by Students and AITools alike.
public struct ConsentSheet: View {
    let centreName: String
    let agree: () async -> Bool
    let close: () -> Void
    @State private var agreeing = false
    /// The board's sheet starts 470 pt down an 852 pt screen.
    public static var boardFraction: CGFloat {
        0.45
    }

    public static let text = "A photo of a register or an answer sheet carries children's names and details. It is "
        + "sent to our AI service (Claude, by Anthropic) only to be read, and is kept neither there nor by us. "
        + "Make sure the parents are fine with their details being kept in Tutor Central."

    public init(centreName: String, agree: @escaping () async -> Bool, close: @escaping () -> Void) {
        self.centreName = centreName
        self.agree = agree
        self.close = close
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Before the first photo", cancel: ("Cancel", close))
            Text(Self.text)
                .typeStyle(Tokens.subhead)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
            Text("Asked once for \(centreName), and recorded with the date.")
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("I agree, continue") {
                Task {
                    agreeing = true
                    _ = await agree()
                    agreeing = false
                }
            }
            .buttonStyle(.primary(.sheet, loading: agreeing))
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
