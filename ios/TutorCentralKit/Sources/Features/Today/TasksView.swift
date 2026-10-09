import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the Tasks screen: the add field in use.
public enum TasksBoardState: Sendable {
    case adding
}

/// Tasks under More (P4-Tasks, -Empty): the add field at the top, "N to do" by due date, then Done with the tick, the
/// struck title and the done day, and Clear. The circle completes a row; so does a swipe across it.
public struct TasksView: View {
    let store: TasksStore
    let boardState: TasksBoardState?
    /// AppShell's: the offline or sync line under the title (D39).
    let status: RootStatus
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: TasksStore, boardState: TasksBoardState? = nil, status: RootStatus = .online) {
        self.store = store
        self.boardState = boardState
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                navigationRow
                if let line = status.line {
                    StatusLine(line)
                }
                TaskInlineAdd(store: store, showsFocus: boardState == .adding, autofocus: false)
                if let error = store.error {
                    TasksErrorLine(error) { Task { await store.load() } }
                }
                if store.open.isEmpty, store.done.isEmpty, !store.loading {
                    Card {
                        EmptyRow(
                            symbol: "checkmark.circle",
                            title: "Nothing on your list",
                            line: "Add a task when there's something to remember. "
                                + "Done tasks stay here until you clear them."
                        )
                    }
                } else {
                    openSection
                    if !store.done.isEmpty {
                        doneSection
                    }
                }
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
        .task { await store.loadIfNeeded() }
        .onChange(of: store.lastSavedAt) { Haptic.play(.success) }
    }

    private var navigationRow: some View {
        ZStack {
            Text("Tasks").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
            }
        }
    }

    @ViewBuilder private var openSection: some View {
        let open = store.open
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.openTitle)
            if !open.isEmpty {
                TaskList(store: store, tasks: open)
            }
        }
    }

    private var doneSection: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Done", action: ("Clear", { Task { await store.clearDone() } }))
            TaskList(store: store, tasks: store.done)
        }
    }
}

/// A card of task rows: the circle completes or reopens, a swipe completes, the due or done day on the right.
struct TaskList: View {
    let store: TasksStore
    let tasks: [TaskItem]

    var body: some View {
        Card {
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    let trailing = store.trailing(for: task)
                    TaskRow(
                        title: task.title, done: task.isDone, trailing: trailing?.text, trailingTone: trailing?.tone,
                        toggle: { Task { await store.setDone(task.id, !task.isDone) } }
                    )
                    .rowDivider(task.id != tasks.last?.id)
                }
            }
        }
    }
}

/// A read that failed: the line and Retry (Today's pattern).
struct TasksErrorLine: View {
    let text: String
    let retry: () -> Void

    init(_ text: String, retry: @escaping () -> Void) {
        self.text = text
        self.retry = retry
    }

    var body: some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry", action: retry).buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}
