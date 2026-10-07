import Data
import DesignSystem
import Domain
import SwiftUI

/// The app's root: the session gate picks sign-in, onboarding or the tabs. A launch state (`bun shots`) starts it
/// with the fakes and the boards' data; the Kit states show the Kit (debug builds only).
public struct RootView: View {
    @AppStorage(Appearance.storageKey) private var storedAppearance: String?
    @State private var session: SessionStore
    @State private var toasts = ToastCenter()
    private let deps: Dependencies
    private let launch: LaunchState?

    @MainActor public init() {
        let launch = LaunchState.fromArguments()
        let deps: Dependencies = if let launch, launch != .placeholder {
            Fixtures.dependencies(for: launch)
        } else {
            // A build without Supabase values still opens, at sign-in.
            (try? Dependencies.live()) ?? Fixtures.dependencies(for: .signin)
        }
        let initial = launch.map(Fixtures.initialState(for:)) ?? .loading
        self.deps = deps
        self.launch = launch
        _session = State(initialValue: SessionStore(deps: deps, initial: initial))
    }

    private var appearance: Appearance {
        Appearance.resolve(arguments: ProcessInfo.processInfo.arguments, stored: storedAppearance)
    }

    public var body: some View {
        content
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
            PlaceholderRoot(line: "Sign in arrives with its board.")
        case .needsOnboarding:
            PlaceholderRoot(line: "Onboarding arrives with its board.")
        case .ready:
            PlaceholderRoot(line: "The tabs arrive with their boards.")
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

/// A root whose board is built in a later task of this phase; replaced as each lands.
struct PlaceholderRoot: View {
    let line: String

    var body: some View {
        Text(line)
            .typeStyle(Tokens.subhead)
            .foregroundStyle(Tokens.text2.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Tokens.ground.color)
    }
}
