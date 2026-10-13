import SwiftUI
import UIKit

/// The one UIKit wrapper in the design system (D8): SwiftUI cannot make a colour that follows the appearance without an
/// asset catalog, and the tokens live in Swift so the document test can read them (D25). `UIColor(dynamicProvider:)`
/// resolves per trait collection, so `preferredColorScheme` (D23) and the system both work.
enum DynamicColor {
    static func make(dark: RGBA, light: RGBA) -> Color {
        Color(uiColor: uiColor(dark: dark, light: light))
    }

    static func uiColor(dark: RGBA, light: RGBA) -> UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor }
    }
}

/// The system alert's tint (`docs/design/feedback.md`): a lone OK is the alert's one action, drawn in `accent` as the
/// boards draw it (U33-Event-Gone, P20-Switched-Off). SwiftUI's `.tint` does not reach the alert, which UIKit presents.
public enum AlertTint {
    @MainActor public static func apply() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = DynamicColor.uiColor(
            dark: Tokens.accent.dark, light: Tokens.accent.light
        )
    }
}
