import SwiftUI

/// The press of every control: scale to `pressScale` in `press` seconds with `easeOut`; nothing when reduced motion is
/// on.
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.pressEffect(configuration.isPressed)
    }
}

struct PressEffect: ViewModifier {
    let pressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed && !reduceMotion ? Tokens.pressScale : 1)
            .animation(reduceMotion ? nil : Tokens.pressAnimation, value: pressed)
    }
}

extension View {
    func pressEffect(_ pressed: Bool) -> some View {
        modifier(PressEffect(pressed: pressed))
    }
}

public extension View {
    /// The whole view presses as one control.
    func pressable() -> some View {
        buttonStyle(PressableStyle())
    }
}

public extension Tokens {
    /// `press` with `easeOut`.
    static let pressAnimation = Animation.timingCurve(easeOut, duration: press)
}

public extension EnvironmentValues {
    /// Draws controls as if pressed: the Kit shows the pressed state beside the default one.
    @Entry var showsPressed = false
}
