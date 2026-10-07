import Data
import DesignSystem
import Domain
import Onboarding
import Settings
import SwiftUI
import Today

/// The app's root: the session gate picks sign-in, onboarding or the tabs. A launch state (`bun shots`) starts it
/// with the fakes and the boards' data; the Kit states show the Kit (debug builds only).
public struct RootView: View {
    @AppStorage(Appearance.storageKey) private var storedAppearance: String?
    @State private var session: SessionStore
    @State private var toasts = ToastCenter()
    @State private var tabs: TabsState
    @State private var today: TodayStore?
    @Environment(\.scenePhase) private var scenePhase
    private let deps: Dependencies
    private let launch: LaunchState?

    @MainActor public init() {
        let launch = LaunchState.fromArguments()
        let deps: Dependencies = if let launch, launch != .placeholder {
            Fixtures.dependencies(for: launch)
        } else {
            // A build without Supabase values still opens, at sign-in.
            Self.live ?? Fixtures.dependencies(for: .signin)
        }
        let initial = launch.map(Fixtures.initialState(for:)) ?? .loading
        self.deps = deps
        self.launch = launch
        _session = State(initialValue: SessionStore(deps: deps, initial: initial))
        let tabs = TabsState(selected: launch.flatMap(Self.tab(for:)) ?? .today)
        if launch == .settings {
            tabs.push(.settings)
        }
        _tabs = State(initialValue: tabs)
    }

    /// One Supabase client for the life of the process. SwiftUI makes a new RootView whenever the scene re-evaluates;
    /// a client per RootView would sign in on one and read on another that never saw the session.
    private static let live: Dependencies? = try? Dependencies.live()

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
            .onOpenURL { url in
                guard let link = DeepLink(url: url), session.isReady else { return }
                if !tabs.open(link) {
                    toasts.show("That opens in a later build.")
                }
            }
            .onChange(of: scenePhase) { _, phase in
                // The foreground refresh hook: the centre and profile read again when the app comes back.
                if phase == .active, launch == nil {
                    Task { await session.refresh() }
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
        case .ready:
            TabsView(
                state: tabs,
                build: deps.bundleVersion,
                toasts: toasts,
                today: { todayView },
                settings: { settingsView }
            )
        }
    }

    static func tab(for state: LaunchState) -> AppTab? {
        switch state {
        case .laterStudents: .students
        case .laterFees: .fees
        case .laterAttendance: .attendance
        case .laterMore: .more
        default: nil
        }
    }

    static func signInFixture(_ state: LaunchState) -> SignInFixture? {
        switch state {
        case .signinEmail: .email
        case .signinCode: .code
        case .signinCodeWrong: .codeWrong
        case .signinPassword: .password
        default: nil
        }
    }

    @ViewBuilder private var settingsView: some View {
        if case let .ready(workspace) = session.state {
            let store = SettingsStore(
                workspace: workspace,
                auth: deps.auth,
                centres: deps.centres,
                version: deps.bundleVersion
            )
            SettingsView(
                store: store,
                boardState: launch == .settings,
                onWorkspaceChanged: { changed in
                    session.workspaceChanged(changed)
                    today?.workspaceChanged(changed)
                },
                onMessage: { toasts.show($0) }
            )
        }
    }

    /// One Today store for the life of the workspace, so its counts survive a tab switch.
    @ViewBuilder private var todayView: some View {
        if case let .ready(workspace) = session.state {
            let store = today ?? TodayStore(workspace: workspace, counts: deps.counts, now: deps.now)
            TodayView(
                store: store,
                actions: TodayActions(
                    openSettings: { tabs.push(.settings) },
                    openTab: { tabs.select($0) },
                    openLater: { target in
                        switch target {
                        case .schedule: tabs.push(.later(.schedule))
                        case .tasks: tabs.push(.later(.tasks))
                        case .students: tabs.select(.students)
                        }
                    }
                )
            )
            .onAppear {
                if today == nil {
                    today = store
                }
            }
        }
    }

    #if DEBUG
        static func kitSection(_ state: LaunchState?) -> KitView.Section? {
            switch state {
            case .kit: .controls
            case .kitFields: .fields
            case .kitSurfaces: .surfaces
            case .kitPatterns: .patterns
            case .kitDialog: .dialog
            default: nil
            }
        }
    #endif
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
