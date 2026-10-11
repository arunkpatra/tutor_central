import SwiftUI

/// Two-language message sheet (components.md 10.5, P10-TestTomorrow): the Phase 4 message sheet with Edit in the
/// header,
/// the message well labelled with its language, and "In English, for you" on `surface2` in `rowLine` `text2`. An
/// English message is one block (`english` nil). Open WhatsApp is loading while `open` logs and opens the link.
public struct TwoLanguageMessageSheet: View {
    let title: String
    let name: String
    let parentLine: String
    let languageTitle: String
    @Binding var message: String
    let english: String?
    let note: String
    let canOpen: Bool
    let open: () async -> Void
    let close: () -> Void
    @State private var editing = false
    @State private var opening = false

    public init(
        title: String, name: String, parentLine: String, languageTitle: String, message: Binding<String>,
        english: String?, note: String, canOpen: Bool, open: @escaping () async -> Void, close: @escaping () -> Void
    ) {
        self.title = title
        self.name = name
        self.parentLine = parentLine
        self.languageTitle = languageTitle
        _message = message
        self.english = english
        self.note = note
        self.canOpen = canOpen
        self.open = open
        self.close = close
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: title, cancel: ("Cancel", close), save: .init(editing ? "Done" : "Edit", enabled: true) {
                editing.toggle()
            })
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                    HStack(spacing: Tokens.cardPaddingCompact) {
                        Avatar(name: name, size: MessageSheet.avatarSize)
                        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                            Text(name).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                            Text(parentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                        Text("Message · \(languageTitle)").typeStyle(Tokens.footnote)
                            .foregroundStyle(Tokens.text2.color)
                        well
                    }
                    if let english {
                        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                            Text("In English, for you").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                            Text(english)
                                .typeStyle(Tokens.rowLine)
                                .foregroundStyle(Tokens.text2.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Tokens.cardPaddingCompact)
                                .background(
                                    Tokens.surface2.color,
                                    in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous)
                                )
                        }
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
            .disabled(!canOpen || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .modifier(SheetToasts())
        .presentationDetents([.fraction(MessageSheet.boardFraction), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    @ViewBuilder private var well: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
        Group {
            if editing {
                TextField("Message", text: $message, axis: .vertical).lineLimit(4 ... 12)
            } else {
                Text(message).textSelection(.enabled)
            }
        }
        .typeStyle(Tokens.body)
        .foregroundStyle(Tokens.text.color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.cardPaddingCompact)
        .background(Tokens.well.color, in: shape)
        .overlay(shape.strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline))
        .shadowed(Tokens.shadowWell, radius: Tokens.radiusControl)
    }
}
