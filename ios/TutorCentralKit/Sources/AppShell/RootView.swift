import DesignSystem
import SwiftUI

/// The app's root. The Kit states show the Kit (debug builds only); the shell (tabs, session gate) arrives with the
/// sign-in boards.
public struct RootView: View {
    @AppStorage(Appearance.storageKey) private var storedAppearance: String?

    public init() {}

    private var appearance: Appearance {
        Appearance.resolve(arguments: ProcessInfo.processInfo.arguments, stored: storedAppearance)
    }

    public var body: some View {
        content.preferredColorScheme(appearance.colorScheme)
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
            if let section = Self.kitSection(LaunchState.fromArguments()) {
                KitView(startAt: section)
            } else {
                placeholder
            }
        #else
            placeholder
        #endif
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Text("Tutor Central")
                .font(.title2.weight(.semibold))
            Text("Foundation build. Screens arrive in Phase 2.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityIdentifier("root.placeholder")
    }

    #if DEBUG
        static func kitSection(_ state: LaunchState?) -> KitView.Section? {
            switch state {
            case .kit: .controls
            case .kitFields: .fields
            case .kitSurfaces: .surfaces
            case .kitPatterns: .patterns
            case .kitDialog: .dialog
            case .placeholder, nil: nil
            }
        }
    #endif
}
