import Data
import DesignSystem
import Domain
import SwiftUI
import UIKit

/// What a launch state opens on marks from a photo: the rows read (P14-Marks-Confirm), a row's sheet (P14-Marks-Edit),
/// or reading (P14-Marks-Reading).
public enum ReadMarksBoardState: Hashable, Sendable {
    case reading, confirm, edit
}

/// Marks from a photo (P14-Marks-Reading, -Confirm, -Light, -Edit): the student, the photo's pages with Add a page,
/// reading with Cancel, the rows read to tick, open and date, the AI line and Save N marks. Save goes back to the page
/// with the toast and Undo.
public struct ReadMarksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @Environment(ToastCenter.self) private var toasts: ToastCenter?
    @State private var store: ReadMarksStore
    @State private var addingPage = false
    @State private var editing: ReadMarksStore.Row?
    @State private var topInset: CGFloat = 0
    let boardState: ReadMarksBoardState?
    /// The page's Marks read again once saved or undone (AppShell's).
    let onSaved: () -> Void

    public init(store: ReadMarksStore, boardState: ReadMarksBoardState? = nil, onSaved: @escaping () -> Void = {}) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.onSaved = onSaved
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Marks from a photo") { leave() }
                hero
                PagesWell(
                    label: "The photo", image: store.pages.first.flatMap { UIImage(data: $0.data) },
                    line: store.pagesLine, addPage: store.canAddPage ? { addingPage = true } : nil
                )
                content
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
        .photoPageChooser(isPresented: $addingPage, purpose: "photograph a report card") { page in
            store.addAndRead(page)
        }
        .sheet(item: $editing) { row in
            ReadMarkEditSheet(
                row: row, subjects: store.subjectChoices(row.mark.subject), today: store.today,
                save: { mark in
                    store.edit(row.id, mark)
                    editing = nil
                },
                remove: {
                    store.remove(row.id)
                    editing = nil
                },
                close: { editing = nil }
            )
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task { await setUp() }
    }

    private var hero: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Avatar(name: store.heroName)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(store.heroName).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                Text(store.heroLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var content: some View {
        switch store.stage {
        case .reading:
            CreatingCard(
                title: "Reading the marks",
                line: "Usually under a minute. Each subject's test, date and score are picked out for you to check.",
                cancel: { store.cancel() }
            )
        case let .failed(words):
            Card {
                EmptyRow(symbol: "doc.text.magnifyingglass", title: "No marks read", line: words)
            }
        case .read, .saving:
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader(store.title)
                Card {
                    VStack(spacing: 0) {
                        ForEach(store.rows) { row in
                            MarkReadRow(
                                title: row.title, line: row.line, lineIsMissing: row.lineIsMissing, score: row.score,
                                ticked: row.ticked, toggle: { store.toggle(row.id) }, open: { editing = row }
                            )
                            .rowDivider(row.id != store.rows.last?.id)
                        }
                    }
                }
            }
        case .choosing:
            EmptyView()
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                if store.stage == .read || store.stage == .saving {
                    Text(store.aiLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
                Button(store.saveLabel) { save() }
                    .buttonStyle(.primary(.form, loading: store.stage == .saving))
                    .disabled(!store.canSave)
                Text(store.stage == .read || store.stage == .saving ? store.readFootnote : store.footnote)
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func save() {
        Task {
            guard await store.save(), let toast = store.toast else { return }
            Haptic.play(.success)
            onSaved()
            let undo = store
            let saved = onSaved
            toasts?.show(toast, action: ("Undo", {
                Task {
                    if let words = await undo.undo() {
                        notices?.show(words)
                    }
                    saved()
                }
            }))
            dismiss()
        }
    }

    private func leave() {
        store.cancel()
        dismiss()
    }

    private func setUp() async {
        await store.prepare()
        switch boardState {
        case .reading:
            store.showReading()
        case .confirm, .edit:
            await store.read()
            if boardState == .edit {
                editing = store.rows.last
            }
        case nil:
            if store.stage == .choosing {
                store.begin()
            }
        }
    }
}
