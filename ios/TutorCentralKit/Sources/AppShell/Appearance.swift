import Foundation
import SwiftUI

/// Light or dark (D23). The app opens dark; a stored choice (Settings, from its board) can make it light or follow the
/// iPhone. A launch argument wins over both, so `bun shots` can photograph either appearance (D7, D13).
public enum Appearance: String, CaseIterable, Sendable {
    case system
    case dark
    case light

    /// The key the choice is stored under in `UserDefaults`.
    public static let storageKey = "appearance"

    /// `--appearance <name>` from the launch arguments, else the stored choice, else dark.
    public static func resolve(arguments: [String], stored: String?) -> Appearance {
        let asked = arguments.firstIndex(of: "--appearance").flatMap { i in
            arguments.indices.contains(i + 1) ? Appearance(rawValue: arguments[i + 1]) : nil
        }
        return asked ?? stored.flatMap(Appearance.init(rawValue:)) ?? .dark
    }

    /// Nil follows the iPhone's setting.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }
}
