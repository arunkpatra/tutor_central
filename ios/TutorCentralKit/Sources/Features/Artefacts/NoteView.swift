import DesignSystem
import Domain
import SwiftUI
import UIKit

/// What a launch state opens on the note: the two-language sheet up (P10-Note-Send), the note being written, or Write
/// again's menu (P21-Note-Again).
public enum NoteBoardState: Hashable, Sendable {
    case send
    case writing
    case reasons
}

/// The weekly note and can-now-do (P10-Note, -Light, -Send; P10-CanNowDo): the student, "Moved up" for the ladder, the
/// note in the parent's language (editable, its counter), the English beside it, what it says; the footer with the AI
/// line, Write again, Copy and Send on WhatsApp, which opens the two-language sheet.
public struct NoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State private var store: NoteStore
    @State private var sending = false
    @State private var topInset: CGFloat = 0
    @State private var reasons = false
    @State private var askingReason = false
    let boardState: NoteBoardState?
    static let writingLine = "Usually under a minute. From this week's record."

    public init(store: NoteStore, boardState: NoteBoardState? = nil) {
        _store = State(initialValue: store)
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.title) { dismiss() }
                hero
                if let ladder = store.ladder {
                    VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                        SectionHeader(ladder.heading)
                        LadderStrip(area: ladder.area, steps: ladder.steps, current: ladder.current, line: ladder.line)
                    }
                }
                note
                if !store.facts.isEmpty {
                    FactsCard(
                        title: "What it says",
                        rows: store.facts.map { FactsCard.Row(label: $0.label, fact: $0.fact, symbol: $0.symbol) }
                    )
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .scrollDismissesKeyboard(.interactively)
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .sheet(isPresented: $sending) { sendSheet }
        .overlay {
            if reasons {
                GlassMenu(
                    eyebrow: "Write again",
                    rows: AgainMenu.rows(
                        NoteReason.self,
                        pick: { reason in Task { await store.writeAgain(reason) } },
                        ask: {
                            askingReason = true
                        }
                    ),
                    alignment: .bottom
                ) { reasons = false }
            }
        }
        .sheet(isPresented: $askingReason) {
            ReasonSheet(title: "Write again", action: "Write", onMake: { words in
                askingReason = false
                Task { await store.writeAgain(.own(words)) }
            }, onClose: { askingReason = false })
        }
        .onChange(of: store.alert) { _, alert in
            guard let alert else { return }
            notices?.show(alert)
            store.alert = nil
        }
        .onChange(of: store.stage) { _, stage in
            if case let .failed(words) = stage, store.canRetry {
                notices?.show(words, retry: { Task { await store.make() } })
            }
        }
        .task {
            guard boardState != .writing else { return }
            await store.load()
            if boardState == .send {
                sending = true
            } else if boardState == .reasons {
                reasons = true
            }
        }
    }

    private var hero: some View {
        Card {
            HStack(spacing: Tokens.cardPaddingCompact) {
                Avatar(name: store.heroName, size: MessageSheet.avatarSize)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(store.heroName).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                    Text(store.heroLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(Tokens.cardPaddingCompact)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder private var note: some View {
        switch store.stage {
        case .ready:
            Group {
                NoteWell(title: store.wellTitle, text: $store.message, limit: NoteStore.limit, helper: NoteStore.helper)
                if let english = store.english {
                    EnglishBlock(english)
                }
            }
            .opacity(store.rewriting != nil ? Tokens.opacityStale : 1)
            .disabled(store.rewriting != nil)
        case .setAside:
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader(store.wellTitle)
                SetAsideCard(line: store.setAsideLine) { store.writeMyself() }
            }
        case let .failed(words):
            Card { EmptyRow(symbol: "text.bubble", title: "No note yet", line: words) }
        case .loading, .writing:
            CreatingCard(title: store.writingTitle, line: Self.writingLine, cancel: nil)
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(store.aiLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if store.rewriting != nil {
                    HStack(spacing: Tokens.inline) {
                        RefreshSpinner()
                        Text(store.regeneratingLine)
                            .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    }
                } else {
                    Button("Write again") { reasons = true }
                        .buttonStyle(.quiet(emphasised: true))
                        .disabled(store.stage != .ready && store.stage != .setAside)
                }
                HStack(spacing: Tokens.tileGap) {
                    CopyButton(copy: { Task { await store.copy() } })
                        .disabled(!store.canSend)
                    Button { sending = true } label: {
                        Label("Send on WhatsApp", systemImage: "message").typeStyle(Tokens.buttonStrong)
                            .singleLineTitle()
                    }
                    .buttonStyle(.primary(.form))
                    .disabled(!store.canSend)
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
        }
    }

    private var sendSheet: some View {
        let words = store.sendSheet
        return TwoLanguageMessageSheet(
            title: words.title, name: store.heroName, heading: words.heading, parentLine: words.parentLine,
            languageTitle: store.languageTitle, message: $store.message, english: store.english, note: words.note,
            signature: store.signatureLines, canOpen: store.canSend,
            open: {
                if await store.send() {
                    sending = false
                }
            },
            close: { sending = false }
        )
    }
}

/// A note the check set aside (P21-Note-SetAside): the card in the well's place, the message tile, the words, a rule,
/// then the quiet Write it myself in its own row.
private struct SetAsideCard: View {
    let line: String
    let writeMyself: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: Tokens.cardPaddingCompact) {
                    IconTile(symbol: "text.bubble")
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(NoteStore.setAsideTitle).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                        Text(line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Tokens.cardPaddingCompact)
                .accessibilityElement(children: .combine)
                .rowDivider()
                Button("Write it myself", action: writeMyself)
                    .buttonStyle(.quiet(emphasised: true))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Tokens.cardPaddingCompact)
                    .padding(.vertical, Tokens.rowPaddingDense)
            }
        }
    }
}
