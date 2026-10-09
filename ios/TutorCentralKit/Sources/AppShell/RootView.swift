import Attendance
import Data
import DesignSystem
import Domain
import Fees
import Onboarding
import Settings
import Students
import SwiftUI
import Today

/// The app's root: the session gate picks sign-in, onboarding or the tabs. A launch state (`bun shots`) starts it
/// with the fakes and the boards' data; the Kit states show the Kit (debug builds only).
public struct RootView: View {
    @AppStorage(Appearance.storageKey) private var storedAppearance: String?
    @State var session: SessionStore
    @State var toasts = ToastCenter()
    @State var shell: ShellState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) var systemOpenURL
    @Environment(\.authorizationController) var authorizationController
    let deps: Dependencies
    let launch: LaunchState?

    @MainActor public init() {
        let launch = LaunchState.fromArguments()
        let deps: Dependencies = if let launch, launch != .placeholder {
            Fixtures.dependencies(for: launch)
        } else {
            Self.liveOrFakesInDebug()
        }
        let initial = launch.map(Fixtures.initialState(for:)) ?? .loading
        self.deps = deps
        self.launch = launch
        _session = State(initialValue: SessionStore(deps: deps, initial: initial))
        let tabs = TabsState(selected: launch.flatMap(Self.tab(for:)) ?? .today)
        for route in launch.map(Self.initialRoutes(for:)) ?? [] {
            tabs.push(route)
        }
        let shell = ShellState(tabs: tabs)
        Self.follow(initial, shell: shell, deps: deps)
        if launch == .syncSending {
            // P7-Sync-Sending: back online, three changes going.
            shell.runState = .sending(3)
        }
        _shell = State(initialValue: shell)
    }

    /// The shell follows the session: a centre's place, its queue and the queue's runner.
    static func follow(_ state: SessionStore.State, shell: ShellState, deps: Dependencies) {
        shell.sessionChanged(state, files: deps.filesDirectory)
        guard case let .ready(workspace) = state, shell.runner == nil, let queue = shell.queue else { return }
        shell.runner = QueueRunner(
            queue: queue, centre: workspace.centre.id, attendance: deps.attendance, fees: deps.fees,
            messages: deps.messages
        )
    }

    /// One Supabase client for the life of the process. SwiftUI makes a new RootView whenever the scene re-evaluates;
    /// a client per RootView would sign in on one and read on another that never saw the session.
    private static let live: Dependencies? = try? Dependencies.live()

    /// A debug build without Supabase values (previews, a fresh clone) opens on the fakes. A release build without
    /// them is a broken build: it stops at launch with the reason, never pretending to sign in (the TestFlight lane
    /// refuses to build without the values).
    private static func liveOrFakesInDebug() -> Dependencies {
        if let live {
            return live
        }
        #if DEBUG
            return Fixtures.dependencies(for: .signin)
        #else
            fatalError("This build has no Supabase settings (SUPABASE_URL, SUPABASE_ANON_KEY in Info.plist).")
        #endif
    }

    private var appearance: Appearance {
        Appearance.resolve(arguments: ProcessInfo.processInfo.arguments, stored: storedAppearance)
    }

    public var body: some View {
        content
            .overlay(alignment: .bottom) {
                // The tabs draw their own host above the tab bar.
                if !session.isReady {
                    ToastHost(toasts: toasts)
                }
            }
            .onOpenURL { openLink($0) }
            .onChange(of: scenePhase) { _, phase in
                // The foreground refresh hook: the centre and profile read again when the app comes back.
                if phase == .active, launch == nil {
                    Task {
                        await session.refresh()
                        await runQueue()
                        // The reminders plan from the classes as they are now, not as first read.
                        await shell.register?.refresh()
                        replanReminders()
                    }
                }
            }
            .onChange(of: session.state) { _, state in
                Self.follow(state, shell: shell, deps: deps)
                if session.isReady {
                    Task { await runQueue() }
                    replanReminders()
                    NotificationDelegate.shared.onOpen = { openLink($0) }
                } else {
                    NotificationDelegate.shared.onOpen = nil
                }
            }
            .environment(session)
            .environment(toasts)
            .preferredColorScheme(appearance.colorScheme)
            .task {
                if launch == nil {
                    await session.start()
                }
            }
            .task { await followConnectivity() }
    }

    /// A `tutorcentral://` link, from outside or from a tapped reminder.
    func openLink(_ url: URL) {
        guard let link = DeepLink(url: url), session.isReady else { return }
        if !shell.tabs.open(link) {
            toasts.show("That opens in a later build.")
        }
        if case let .attendance(date, classID) = link, case let .ready(workspace) = session.state {
            openAttendance(classID: classID, date: date.flatMap(Day.init(iso:)), in: workspace)
        }
        if case let .fees(month) = link, case let .ready(workspace) = session.state {
            openFees(month: Self.linkMonth(month), in: workspace)
        }
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
            if let section = Self.kitSection(launch) {
                KitView(startAt: section)
            } else {
                gate
            }
        #else
            gate
        #endif
    }

    @ViewBuilder private var gate: some View {
        switch session.state {
        case .loading:
            LoadingRoot(error: session.lastError) { Task { await session.refresh() } }
        case .signedOut:
            SignInView(
                auth: deps.auth,
                legal: Legal.links,
                fixture: launch.flatMap(Self.signInFixture),
                deletedCentre: launch == .signinDeleted ? Fixtures.meeraWorkspace.centre.name : session.deletedCentre,
                onSignedIn: { await session.signedIn($0) },
                onMessage: { toasts.show($0) }
            )
        case let .needsOnboarding(user):
            OnboardingView(
                user: user,
                auth: deps.auth,
                centres: deps.centres,
                boardState: launch == .onboarding,
                onCreated: { session.centreCreated($0) },
                onMessage: { toasts.show($0) }
            )
            // A newer answer about the same sign-in (Apple's name arriving) makes a fresh form.
            .id(user)
        case .ready:
            TabsView(
                state: shell.tabs,
                toasts: toasts,
                today: { todayView },
                students: { studentsView },
                studentDetail: { studentDetailView($0) },
                classes: { classesView },
                classDetail: { classDetailView($0) },
                settings: { settingsScreen($0) },
                attendance: { attendanceView },
                history: { historyView },
                studentMonth: { studentMonthView($0) },
                schedule: { scheduleView(openEvent: $0) },
                tasks: { tasksView },
                fees: { feesView },
                studentFees: { studentFeesView($0) },
                payments: { paymentsView },
                reports: { reportsView },
                tools: { toolsView($0) }
            )
        }
    }

    /// One register for the life of the workspace, so the list, the search and the scroll survive a tab switch.
    func register(for workspace: Workspace) -> RegisterStore {
        if let register = shell.register {
            return register
        }
        let made = RegisterStore(
            workspace: workspace,
            students: deps.students,
            classes: deps.classes,
            // The fixtures keep theirs in their own folder.
            cache: deps.cachesRegister
                ? .forCentre(workspace.centre.id)
                : deps.filesDirectory.map { RegisterCache.forCentre(workspace.centre.id, directory: $0) },
            now: deps.now
        )
        made.onChanged = { replanReminders() }
        // Kept at once, in the same pass: the detail pushed by a launch state or a link reads the same register as the
        // list.
        shell.register = made
        return made
    }

    @ViewBuilder private var studentsView: some View {
        if case let .ready(workspace) = session.state {
            let store = register(for: workspace)
            StudentsView(
                store: store,
                actions: studentsActions,
                navigation: studentsNavigation,
                boardState: launch.flatMap(Self.studentsBoardState)
                    ?? (launch == .offlineWriteRefused ? .newStudentFilled : nil),
                status: rootStatus(savedAt: store.savedAt, offlineRead: store.offlineRead)
            )
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                Haptic.play(.error)
                toasts.show(message, action: store.canRetry ? Self.retry(store) : nil)
                store.message = nil
            }
            .onAppear {
                // P6-Scan-Saved: the list after Add, with its toast.
                if launch == .scanSaved {
                    toasts.show(ScanReview.addedToast(count: 7), action: ("Undo", {}), stay: .seconds(3600))
                }
                // P7-Offline-WriteRefused: Save on the filled sheet, offline.
                if launch == .offlineWriteRefused {
                    toasts.show(OfflineRefusal.words(for: .addStudent), stay: .seconds(3600))
                }
            }
        }
    }

    @ViewBuilder private var classesView: some View {
        if case let .ready(workspace) = session.state {
            ClassesView(
                register: register(for: workspace),
                navigation: studentsNavigation,
                boardState: launch.flatMap(Self.classesBoardState)
            )
        }
    }

    @ViewBuilder private func classDetailView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            ClassDetailView(
                id: id,
                register: register(for: workspace),
                actions: studentsActions,
                navigation: studentsNavigation,
                boardState: launch.flatMap(Self.classDetailBoardState)
            )
        }
    }

    @ViewBuilder private func studentDetailView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            let register = register(for: workspace)
            StudentDetailView(
                store: StudentDetailStore(
                    id: id,
                    register: register,
                    attendance: deps.attendance,
                    messages: deps.messages
                ),
                register: register,
                actions: studentsActions,
                navigation: studentsNavigation,
                boardState: launch.flatMap(Self.studentDetailBoardState),
                onMissing: {
                    shell.tabs.remove(.student(id))
                    toasts.show(StudentDetailStore.missingMessage)
                }
            )
        }
    }
}

/// While the session and the centre are read: the shape of the screen breathing, and when the read failed, the line
/// that says so and Retry (guidelines.md, "States every screen has": the Kit's error pattern on an empty ground).
struct LoadingRoot: View {
    let error: String?
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            Card {
                VStack(spacing: 0) {
                    SkeletonRow().rowDivider()
                    SkeletonRow(widths: (0.4, 0.65))
                }
            }
            if let error {
                HStack {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .labelStyle(InlineLabelStyle())
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                    Spacer()
                    Button("Retry", action: retry).buttonStyle(.quiet)
                }
                .padding(.horizontal, Tokens.rowGapInner)
            }
            Spacer()
        }
        .padding(.horizontal, Tokens.pageSide)
        .padding(.top, Tokens.pageTop)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.ground.color)
    }
}
