import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on Today: the add field open with a due date, scrolled to Tasks (P4-Today-AddingTask).
public enum TodayBoardState: Sendable {
    case addingTask
    /// Scrolled to the end: Coming up, Tasks and the Create with AI row (P6-Today-AITools).
    case aiRow
}

/// Today live, to P4-Today-Soon (dark and light), -Evening, -NoClass and -AddingTask; P2-Today-Empty for a centre with
/// nothing yet: the date and greeting, three counts, the next class, today's classes and events, coming up, tasks. The
/// greeting is the title; the tab's navigation bar is hidden and the status bar sits on glass once scrolled (U1).
public struct TodayView: View {
    let store: TodayStore
    let actions: TodayActions
    let ticks: Bool
    let boardState: TodayBoardState?
    let status: RootStatus
    @State private var topInset: CGFloat = 0

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
                        StartHereCard(openStudents: { actions.openTab(.students) })
                    }
                    if let hero = store.hero {
                        HeroCard(hero: hero) { actions.openMarkAttendance(hero.classID) }
                    }
                    TodaySection(store: store, actions: actions)
                    if !store.comingUp.isEmpty {
                        ComingUpSection(rows: store.comingUp, open: actions.openEvent).id(Self.comingUpID)
                    }
                    TodayTasksSection(store: store.tasks, showsFocus: boardState == .addingTask)
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
                if boardState != nil {
                    try? await Task.sleep(for: .seconds(Tokens.panel))
                    proxy.scrollTo(Self.comingUpID, anchor: .top)
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
    private static let tickSeconds: Double = 60

    private var header: some View {
        HStack(alignment: .bottom) {
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

    /// The three tiles share a height: "Classes today" wrapping makes all three taller, never one (U4).
    private var tiles: some View {
        HStack(spacing: Tokens.tileGap) {
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
                label: "Classes today",
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
