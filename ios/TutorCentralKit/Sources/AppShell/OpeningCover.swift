import DesignSystem
import SwiftUI

/// The launch screen carried on (P7-Launch-Fade): the dark ground and the book, exactly where iOS drew them, held
/// while the session is read and faded into the first screen over `Tokens.opening` once it is ready. No wait is added:
/// it goes as soon as there is something to show. With Reduce Motion the first screen simply appears.
struct OpeningCover: View {
    /// The iOS launch screen's image, 88 pt in the app's asset catalogue.
    static let image = "LaunchBook"

    var body: some View {
        ZStack {
            Tokens.ground.color
            Image(Self.image, bundle: .main)
        }
        .ignoresSafeArea()
        // The launch screen is dark whatever the iPhone's setting; so is its continuation.
        .environment(\.colorScheme, .dark)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Covers the app with the opening until `ready`, then fades it away once.
    func opening(ready: Bool, shown: Bool) -> some View {
        modifier(Opening(ready: ready, shown: shown))
    }
}

private struct Opening: ViewModifier {
    let ready: Bool
    @State var covering: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(ready: Bool, shown: Bool) {
        self.ready = ready
        _covering = State(initialValue: shown && !ready)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if covering {
                    OpeningCover().transition(.opacity)
                }
            }
            .onChange(of: ready, initial: true) { _, isReady in
                guard isReady, covering else { return }
                // Ease in and out, not the app's easeOut: that curve ends a fade in a tenth of a second, which reads
                // as a cut (seen in a recording of the launch).
                withAnimation(
                    ReducedMotion.animation(.easeInOut(duration: Tokens.opening), reduce: reduceMotion)
                ) {
                    covering = false
                }
            }
    }
}
