import SwiftUI

/// The app's root. In Phase 1 it shows one line; the shell (tabs, session gate) arrives in Phase 2 to approved boards.
public struct RootView: View {
    public init() {}

    public var body: some View {
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
}
