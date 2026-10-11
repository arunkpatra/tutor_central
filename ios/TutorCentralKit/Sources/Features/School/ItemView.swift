import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on an item's page: its sheet open (P10-School-Item-Edit), the delete dialog
/// (P10-School-Item-Delete).
public enum ItemBoardState: Sendable {
    case edit
    case delete
}

/// Where an exam's page leads (AppShell's routes): Today at a batch's plan, an artefact, the Test tomorrow sheet.
public struct ItemActions {
    let openToday: (UUID) -> Void
    let openArtefact: (UUID) -> Void
    let testTomorrow: (TestTomorrowAsk) -> Void
    /// The last days' Mark from a photo: Check a paper for the student with the mock's key.
    let markPaper: (Student, Artefact, SchoolItem) -> Void
    /// The last days' Gap report: the exam and the student.
    let openGapReport: (UUID, UUID) -> Void
    /// Who's rows: the student's page (U44).
    let openStudent: ((UUID) -> Void)?

    public init(
        openToday: @escaping (UUID) -> Void, openArtefact: @escaping (UUID) -> Void,
        testTomorrow: @escaping (TestTomorrowAsk) -> Void,
        markPaper: @escaping (Student, Artefact, SchoolItem) -> Void = { _, _, _ in },
        openGapReport: @escaping (UUID, UUID) -> Void = { _, _ in },
        openStudent: ((UUID) -> Void)? = nil
    ) {
        self.openStudent = openStudent
        self.openToday = openToday
        self.openArtefact = openArtefact
        self.testTomorrow = testTomorrow
        self.markPaper = markPaper
        self.openGapReport = openGapReport
    }
}

/// An item's page (P10-School-Item; a homework's or notice's has no Preparation, a holiday's says the batch days it
/// covers): the kind as the title with Edit, the hero, Who, an exam's Preparation, what the school sent, Delete this
/// item.
public struct ItemView: View {
    @Bindable var store: ItemStore
    let boardState: ItemBoardState?
    let actions: ItemActions?
    let back: () -> Void
    @State private var editing: ItemFormStore?
    @State private var deleting = false
    @State private var choosingPaper = false
    @State private var topInset: CGFloat = 0
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(
        store: ItemStore, boardState: ItemBoardState? = nil, actions: ItemActions? = nil, back: @escaping () -> Void
    ) {
        self.store = store
        self.boardState = boardState
        self.actions = actions
        self.back = back
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(
                    title: store.item?.kind.title ?? "Item",
                    action: store.item == nil ? nil : ("Edit", { editing = store.form() }),
                    back: back
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
        .overlay {
            if deleting, let item = store.item {
                ZStack {
                    Tokens.dim.color.ignoresSafeArea().onTapGesture { deleting = false }
                    DialogView(
                        title: "Delete this item?",
                        message: "\(item.title) goes from the School tab and its preparation lines leave the plan. "
                            + "What was already taught stays in the record.",
                        action: "Delete", destructive: true,
                        onCancel: { deleting = false },
                        onAction: delete
                    )
                    .padding(.horizontal, Tokens.pageSide)
                }
                .transition(.opacity)
            }
        }
        .sheet(item: $editing) { form in
            ItemFormSheet(
                store: form,
                onSave: { _ in
                    guard let item = store.item else { return }
                    Task {
                        if await store.save(form.item(from: item)) {
                            editing = nil
                        }
                    }
                },
                onRemove: nil,
                onClose: { editing = nil }
            )
        }
        .task {
            await store.load()
            switch boardState {
            case .edit: editing = store.form()
            case .delete: deleting = true
            case nil: break
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .onChange(of: store.state) { _, state in
            if state == .gone, store.item == nil, !deleting {
                back()
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .loading:
            EmptyView()
        case .failed:
            LoadFailedView("Couldn't load this item.") { Task { await store.load() } }
        case .gone:
            EmptyView()
        case .shown:
            if let hero = store.hero {
                ItemHeroCard(hero: hero)
            }
            if let covered = store.coveredLine {
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader("Batch days")
                    Card {
                        Text(covered).typeStyle(Tokens.rowLine).foregroundStyle(Tokens.text.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, Tokens.rowPaddingDense)
                            .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    }
                }
            } else if !store.who.isEmpty {
                WhoSection(rows: store.who, open: actions?.openStudent)
            }
            if let lastDays = store.lastDays, let item = store.item {
                LastDaysSections(
                    model: lastDays,
                    openMock: { actions?.openArtefact($0) },
                    mark: { markFromPhoto(lastDays, item: item) },
                    openGapReport: { student in actions?.openGapReport(item.id, student) },
                    testTomorrowLine: store.testTomorrowLine,
                    testTomorrow: store.testTomorrowAsk.flatMap { ask in actions.map { actions in
                        { actions.testTomorrow(ask) }
                    } }
                )
                .confirmationDialog("Whose paper?", isPresented: $choosingPaper, titleVisibility: .visible) {
                    ForEach(markable(lastDays)) { student in
                        Button(student.name) { mark(student, lastDays, item) }
                    }
                }
            }
            if !store.preparation.isEmpty {
                PreparationSection(
                    rows: store.preparation,
                    change: store.changeOpensToday.flatMap { batch in actions.map { actions in
                        { actions.openToday(batch) }
                    } },
                    open: open,
                    testTomorrowLine: store.testTomorrowLine,
                    testTomorrow: store.testTomorrowAsk.flatMap { ask in actions.map { actions in
                        { actions.testTomorrow(ask) }
                    } }
                )
            }
            SourceSection(store: store)
            Button { deleting = true } label: {
                Label("Delete this item", systemImage: "trash").frame(maxWidth: .infinity)
            }
            .buttonStyle(.destructive(.card))
            .environment(\.buttonIconSize, Tokens.iconSmall)
        }
    }

    /// The exam's students whose parents agreed.
    private func markable(_ model: LastDaysModel) -> [Student] {
        let ids = Set(model.marked.filter(\.canMark).map(\.id))
        return store.register.activeStudents.filter { ids.contains($0.id) }.sorted { $0.name < $1.name }
    }

    private func markFromPhoto(_ model: LastDaysModel, item: SchoolItem) {
        let students = markable(model)
        if students.count == 1, let only = students.first {
            mark(only, model, item)
        } else if students.isEmpty {
            notices?
                .show(model.marked.first?.consentLine.map { "\($0)." } ?? "No student of this exam can be marked yet.")
        } else {
            choosingPaper = true
        }
    }

    private func mark(_ student: Student, _ model: LastDaysModel, _ item: SchoolItem) {
        guard let mock = model.mock else { return }
        actions?.markPaper(student, mock, item)
    }

    private func open(_ opens: PreparationOpen) {
        switch opens {
        case let .today(batch): actions?.openToday(batch)
        case let .artefact(id): actions?.openArtefact(id)
        }
    }

    private func delete() {
        Task {
            if await store.delete() {
                deleting = false
                back()
            } else {
                deleting = false
            }
        }
    }
}
