import DesignSystem
import Domain
import SwiftUI
import UIKit

/// A progress note's result (P6-Result-ProgressNote), pushed: the student and parent, the note in an editable well,
/// and the footer: the AI line, Copy and Write again, then Send on WhatsApp, which opens the message sheet
/// (P6-ProgressNote-Send).
struct NoteResultView: View {
    let store: AIStore
    let generation: Generation
    let boardState: AIBoardState?
    let onMessage: (String) -> Void
    @State private var text: String
    @State private var sending: Bool
    @State private var consent = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    static var wellHeight: CGFloat {
        220
    }

    static var avatarSize: CGFloat {
        56
    }

    init(store: AIStore, generation: Generation, boardState: AIBoardState?, onMessage: @escaping (String) -> Void) {
        self.store = store
        self.generation = generation
        self.boardState = boardState
        self.onMessage = onMessage
        let note = if case let .progressNote(result) = generation.result {
            result.note
        } else {
            ""
        }
        _text = State(initialValue: note)
        _sending = State(initialValue: boardState == .noteSend)
    }

    private static func note(_ result: GenerationResult) -> String {
        guard case let .progressNote(note) = result else { return "" }
        return note.note
    }

    private var student: Student? {
        generation.studentID.flatMap(store.register.student)
    }

    private var regenerating: Bool {
        store.inFlight?.regenerating == generation.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Progress note") { dismiss() }
                if let student {
                    HStack(spacing: Tokens.cardPaddingCompact) {
                        Avatar(name: student.name, size: Self.avatarSize)
                        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                            Text(student.name).typeStyle(Tokens.title3).foregroundStyle(Tokens.text.color)
                            Text(parentLine(student)).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    MultilineWell(label: "Note", text: $text, placeholder: "", limit: 4000, minHeight: Self.wellHeight)
                    Text("Edit anything before it goes. Tap Write again for a fresh draft.")
                        .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                        .padding(.horizontal, Tokens.fieldGap)
                }
                .opacity(regenerating ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .sheet(isPresented: $sending) { sendSheet }
        .sheet(isPresented: $consent) {
            ConsentSheet(centreName: store.workspace.centre.name) {
                let agreed = await store.recordConsent()
                if agreed {
                    consent = false
                    _ = store.createAgain(generation)
                }
                return agreed
            } close: {
                consent = false
            }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(AIWords.noteLine)
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: Tokens.tileGap) {
                    Button {
                        UIPasteboard.general.string = text
                        onMessage("Copied.")
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.secondary(.form))
                    Button {
                        writeAgain()
                    } label: {
                        Label("Write again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.secondary(.form, loading: regenerating))
                }
                Button {
                    sending = true
                } label: {
                    Label("Send on WhatsApp", systemImage: "message")
                }
                .buttonStyle(.primary(.card))
            }
            .disabled(regenerating)
        }
    }

    @ViewBuilder private var sendSheet: some View {
        if let message = store.noteMessage(generation, text: text) {
            MessageSheet(
                title: "Send the note", name: message.name, parentLine: message.parentLine, text: message.text,
                note: message.url == nil ? "Add the parent's number first." : sendNote(message.firstName),
                canOpen: message.url != nil
            ) {
                await store.openNote(generation, text: text)
                sending = false
            } close: {
                sending = false
            }
        }
    }

    private func sendNote(_ firstName: String) -> String {
        "Opens WhatsApp with the note ready to send. We note the date on \(firstName)'s page. The text is copied "
            + "too, in case WhatsApp can't open."
    }

    private func parentLine(_ student: Student) -> String {
        [student.parentName, student.parentPhone?.display].compactMap(\.self).joined(separator: " · ")
    }

    private func writeAgain() {
        if store.createAgain(generation) == .needsConsent {
            consent = true
        }
    }
}
