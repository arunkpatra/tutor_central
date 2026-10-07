import SwiftUI
import UIKit

/// The one UIKit wrapper in the design system (D8): SwiftUI cannot make a colour that follows the appearance without an
/// asset catalog, and the tokens live in Swift so the document test can read them (D25). `UIColor(dynamicProvider:)`
/// resolves per trait collection, so `preferredColorScheme` (D23) and the system both work.
enum DynamicColor {
    static func make(dark: RGBA, light: RGBA) -> Color {
        Color(uiColor: UIColor { traits in traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor })
    }
}
