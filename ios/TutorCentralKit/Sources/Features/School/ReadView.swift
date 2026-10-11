import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the read screen: the first item's sheet open (P10-School-Confirm-Edit).
public enum ReadBoardState: Sendable {
    case editFirst
}

/// "Check what was read" (P10-School-Confirm, P13-School-Reading): the source well, the reading card while it reads,
/// then one card per item to check; Add in the footer. Back asks before what was read is lost.
public struct ReadView: View {
    @Bindable var store: ReadStore
    let boardState: ReadBoardState?
    let leave: () -> Void
    let done: ([SchoolItem]) -> Void
    @State private var editing: ItemFormStore?
    @State private var leaving = false
    @State private var topInset: CGFloat = 0
    @State private var started = false
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(
        store: ReadStore, boardState: ReadBoardState? = nil, leave: @escaping () -> Void,
        done: @escaping ([SchoolItem]) -> Void
    ) {
        self.store = store
        self.boardState = boardState
        self.leave = leave
        self.done = done
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Check what was read", back: back)
                if store.stage == .pasteWaiting {
                    PasteWell(label: "What the school sent", line: store.pasteLine) { text in
                        Task { await store.paste(text) }
                    }
                } else if store.sourceText != nil || store.sourceImage != nil {
                    SourceWell(label: "What the school sent", text: store.sourceText, image: store.sourceImage)
                }
                if store.stage == .reading {
                    CreatingCard(
                        title: SchoolWords.readingTitle, line: SchoolWords.readingLine, thumbnail: store.sourceImage,
                        cancel: { leaveNow() }
                    )
                } else if store.stage != .pasteWaiting {
                    drafts
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .overlay {
            if leaving {
                ZStack {
                    Tokens.dim.color.ignoresSafeArea().onTapGesture { leaving = false }
                    DialogView(
                        title: "Leave without adding?",
                        message: "Nothing read here is kept.",
                        cancel: "Keep checking", action: "Leave", destructive: false,
                        onCancel: { leaving = false },
                        onAction: leaveNow
                    )
                    .padding(.horizontal, Tokens.pageSide)
                }
                .transition(.opacity)
            }
        }
        .sheet(item: $editing) { form in
            ItemFormSheet(
                store: form,
                onSave: { draft in
                    store.replace(draft)
                    editing = nil
                },
                onRemove: store.drafts.contains { $0.id == form.draft().id } ? {
                    store.remove(form.draft().id)
                    editing = nil
                } : nil,
                onClose: { editing = nil }
            )
        }
        .task {
            guard !started else { return }
            started = true
            await store.read()
            if boardState == .editFirst, let first = store.drafts.first {
                editing = form(first)
            } else if store.source == .typed {
                editing = form(nil)
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .onChange(of: store.stage) { _, stage in
            switch stage {
            case let .failed(words): notices?.show(words, retry: { Task { await store.read() } })
            case let .added(items): done(items)
            default: break
            }
        }
    }

    private var drafts: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.countLine, action: ("Add an item", { editing = form(nil) }))
            ForEach(store.drafts) { draft in
                ItemCard(
                    ticked: Binding(get: { draft.ticked }, set: { _ in store.toggle(draft.id) }),
                    title: draft.title.isEmpty ? "Untitled" : draft.title, kind: SchoolWords.kind(draft.kind),
                    open: { editing = form(draft) },
                    facts: { facts(draft) }
                )
            }
        }
    }

    @ViewBuilder private func facts(_ draft: SchoolItemDraft) -> some View {
        let students = store.register.activeStudents
        let who = SchoolWords.audience(draft.audience, students: students, schools: store.schools)
        FactLine(label: "For", value: who ?? "Choose", missing: who == nil)
        if let subject = draft.subject {
            FactLine(label: "Subject", value: subject)
        }
        if let date = draft.date {
            FactLine(
                label: SchoolWords.dateLabel(draft.kind),
                value: SchoolWords.dateValue(kind: draft.kind, date: date, end: draft.endDate, today: store.today)
            )
        } else {
            FactLine(label: SchoolWords.dateLabel(draft.kind), value: "Not given", missing: true)
        }
        if let portions = draft.portions {
            FactLine(label: "Portions", value: portions)
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(store.footnote)
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    Task { _ = await store.add() }
                } label: {
                    Text(store.addLabel)
                }
                .buttonStyle(.primary(.card, loading: store.stage == .adding))
                .disabled(!store.canAdd)
            }
        }
    }

    private func form(_ draft: SchoolItemDraft?) -> ItemFormStore {
        ItemFormStore(draft: draft, students: store.register.activeStudents, schools: store.schools, today: store.today)
    }

    private func back() {
        if store.drafts.isEmpty || store.stage == .reading {
            leaveNow()
        } else {
            leaving = true
        }
    }

    private func leaveNow() {
        leaving = false
        store.leave()
        leave()
    }
}
