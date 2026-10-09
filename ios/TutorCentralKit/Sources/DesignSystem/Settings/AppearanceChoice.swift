import Foundation
import SwiftUI

/// Light or dark (D23). The app opens dark; Settings' Appearance row stores a choice that can make it light or follow
/// the iPhone. A launch argument wins over both, so `bun shots` can photograph either appearance (D7, D13). In
/// DesignSystem so Settings can offer it without AppShell.
public enum AppearanceChoice: String, CaseIterable, Sendable {
    case dark
    case light
    case system

    /// The key the choice is stored under in `UserDefaults`.
    public static let storageKey = "appearance"

    /// `--appearance <name>` from the launch arguments, else the stored choice, else dark.
    public static func resolve(arguments: [String], stored: String?) -> AppearanceChoice {
        let asked = arguments.firstIndex(of: "--appearance").flatMap { index in
            arguments.indices.contains(index + 1) ? AppearanceChoice(rawValue: arguments[index + 1]) : nil
        }
        return asked ?? stored.flatMap(AppearanceChoice.init(rawValue:)) ?? .dark
    }

    /// "Dark", "Light", "Match iPhone" (the segmented row).
    public var label: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .system: "Match iPhone"
        }
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
