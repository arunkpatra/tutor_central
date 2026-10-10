import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on Today: the add field open with a due date, scrolled to Tasks (P4-Today-AddingTask).
public enum TodayBoardState: Hashable, Sendable {
    case addingTask
    /// Scrolled to the end: Coming up, Tasks and the Create with AI row (P6-Today-AITools).
    case aiRow
    /// Scrolled to the smaller groups, the brief and V1's sections (P10-Today-Plan-Scrolled).
    case scrolledToPlan
    /// Dev's line pressed: its menu (P10-Today-Plan-StudentMenu).
    case lineMenu(UUID)
    /// The Change sheet up (P10-Today-Plan-Change).
    case changeSheet
}

/// Today live, to P4-Today-Soon (dark and light), -Evening, -NoClass and -AddingTask; P2-Today-Empty for a centre with
/// nothing yet: the date and greeting, three counts, the next class, today's classes and events, coming up, tasks. The
/// greeting is the title; the tab's navigation bar is hidden and the status bar sits on glass once scrolled (U1).
public struct TodayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let store: TodayStore
    let actions: TodayActions
    let ticks: Bool
    let boardState: TodayBoardState?
    let status: RootStatus
    @State private var topInset: CGFloat = 0
    /// The batch whose Change sheet is up.
    @State private var changing: ChangingBatch?

    /// `ticks` runs the minute clock (live); the fixtures hold their moment. `status` is AppShell's: the offline or
    /// sync line under the greeting, and whether the AI row is live.
    public init(
        store: TodayStore, actions: TodayActions, ticks: Bool = true, boardState: TodayBoardState? = nil,
        status: RootStatus = .online
    ) {
        self.store = store
        self.actions = actions
        self.ticks = ticks
        self.boardState = boardState
        self.status = status
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    header
                    if let line = status.line {
                        StatusLine(line)
                    }
                    tiles
                    if let error = store.error {
                        refreshError(error)
                    }
                    if store.showsStartHere {
                        StartHereCard(
                            openStudents: { actions.openTab(.students) }, openScanRegister: actions.openScanRegister
                        )
                    }
                    if let hero = store.hero {
                        BatchHeroCard(hero: hero, openClose: actions.openClose)
                    }
                    ForEach(store.planBatches) { batch in
                        if let plan = store.plans[batch.id] {
                            PlanSection(
                                store: plan,
                                title: store.planBatches.count > 1 ? "Today's plan · \(batch.name)" : "Today's plan",
                                open: { opened in
                                    if case let .artefact(id) = opened {
                                        actions.openArtefact(id)
                                    }
                                },
                                change: { changing = ChangingBatch(id: batch.id) },
                                menuFor: lineMenuStudent
                            )
                            .id(Self.planID(batch.id))
                        }
                    }
                    TodaySection(store: store, actions: actions)
                    if !store.comingUp.isEmpty {
                        ComingUpSection(rows: store.comingUp, open: actions.openEvent).id(Self.comingUpID)
                    }
                    TodayTasksSection(store: store.tasks, showsFocus: boardState == .addingTask).id(Self.tasksID)
                    VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                        SectionHeader("Create")
                        Card {
                            ToolRow(
                                symbol: "sparkles", title: "Create with AI",
                                line: "A paper, homework, a worksheet or a progress note", action: actions.openAI
                            )
                            .disabled(status.offline)
                            .opacity(status.offline ? Tokens.opacityDisabled : 1)
                        }
                    }
                }
                .padding(.horizontal, Tokens.pageSide)
                .padding(.top, max(0, Tokens.pageTop - topInset))
                .padding(.bottom, Tokens.contentBottom)
            }
            .statusBarGlass()
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
            .scrollDismissesKeyboard(.interactively)
            .background(Tokens.ground.color)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $changing) { batch in
                if let plan = store.plans[batch.id] {
                    PlanChangeSheet(store: plan, weekday: store.today.weekday(in: store.calendar)) { changing = nil }
                }
            }
            .refreshable {
                await store.load()
                Haptic.play(.impactLight)
            }
            .task {
                store.showCached()
                await store.load()
                if boardState == .addingTask {
                    setUpAddingTask()
                }
                await setUpPlanBoard(proxy)
                if boardState == .addingTask || boardState == .aiRow {
                    try? await Task.sleep(for: .seconds(Tokens.panel))
                    proxy.scrollTo(Self.comingUpID, anchor: .top)
                }
            }
            .onChange(of: store.focusBatch) { _, batch in
                guard let batch else { return }
                withAnimation(ReducedMotion.animation(.default, reduce: reduceMotion)) {
                    proxy.scrollTo(Self.planID(batch), anchor: .top)
                }
            }
            .onChange(of: store.tasks.adding) { _, adding in
                // The field opens above the keyboard, not under it (build 10): once the keyboard is up, the Tasks card
                // is scrolled to the middle of what is left.
                guard adding, boardState == nil else { return }
                Task {
                    try? await Task.sleep(for: .seconds(Tokens.panel))
                    withAnimation(ReducedMotion.animation(.default, reduce: reduceMotion)) {
                        proxy.scrollTo(Self.tasksID, anchor: .center)
                    }
                }
            }
            .task(id: ticks) {
                // The minute clock: the countdown and the next class follow it while Today is on screen.
                while ticks, !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Self.tickSeconds))
                    store.tick(Date())
                }
            }
            .onChange(of: store.tasks.lastSavedAt) { Haptic.play(.success) }
        }
    }

    private static let comingUpID = "coming-up"

    static func planID(_ batch: UUID) -> String {
        "plan-\(batch.uuidString)"
    }

    private var lineMenuStudent: UUID? {
        if case let .lineMenu(student) = boardState {
            return student
        }
        return nil
    }

    /// The plan's board states once the plan is in: scrolled to the second group, the Change sheet up; a link from a
    /// student's page scrolls to its batch's plan.
    private func setUpPlanBoard(_ proxy: ScrollViewProxy) async {
        guard let first = store.planBatches.first(where: { store.plans[$0.id]?.record != nil }) else { return }
        switch boardState {
        case .scrolledToPlan:
            try? await Task.sleep(for: .seconds(Tokens.panel))
            proxy.scrollTo(PlanSection.groupID(first.id, 2), anchor: .top)
        case .changeSheet:
            changing = ChangingBatch(id: first.id)
        default:
            if let batch = store.focusBatch {
                try? await Task.sleep(for: .seconds(Tokens.panel))
                proxy.scrollTo(Self.planID(batch), anchor: .top)
            }
        }
    }

    private static let tasksID = "tasks"
    private static let tickSeconds: Double = 60

    /// The account picture at the top right, level with the date; the greeting wraps under it (P7-Today-Header).
    private var header: some View {
        HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                Eyebrow(store.heading)
                Text(store.greeting)
                    .typeStyle(Tokens.displayCompact)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: Tokens.inline)
            IconButton(initials: store.initials, label: "Account and settings", action: actions.openSettings)
        }
    }

    /// The three tiles share a height: "Classes today" wrapping makes all three taller, never one (U4). At the
    /// accessibility sizes they stand one over another, full width.
    private var tiles: some View {
        AdaptiveRow(spacing: Tokens.tileGap, stackedSpacing: Tokens.tileGap) {
            StatTile(value: "\(store.counts.students)", label: "Students", tone: tone(store.counts.students)) {
                actions.openTab(.students)
            }
            StatTile(
                value: store.counts.due.formatted,
                label: "Due",
                tone: store.counts.due == .zero ? .zero : .due
            ) { actions.openFeesDue() }
            StatTile(
                value: "\(store.counts.classesToday)",
                label: "Batches today",
                tone: tone(store.counts.classesToday)
            ) {
                actions.openSchedule()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .opacity(store.loading ? Tokens.opacityStale : 1)
    }

    private func tone(_ count: Int) -> StatTone {
        count == 0 ? .zero : .plain
    }

    private func refreshError(_ error: String) -> some View {
        HStack {
            Label(error, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry") { Task { await store.load() } }.buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }

    /// P4-Today-AddingTask: Print worksheets for Class 8, due Friday 9 October.
    private func setUpAddingTask() {
        store.tasks.adding = true
        store.tasks.newTitle = "Print worksheets for Class 8"
        store.tasks.newDue = Day(year: 2026, month: 10, day: 9)
    }
}

/// The batch whose Change sheet is up.
struct ChangingBatch: Identifiable, Hashable {
    let id: UUID
}
