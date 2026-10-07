import UIKit

/// The haptics table of design-tokens.md. UIKit's feedback generators are the system's haptics and can be played from
/// an action (SwiftUI's `sensoryFeedback` only answers a changed value). `enabled` is read from UserDefaults
/// ("haptics", default on); Phase 7's Settings row writes it.
public enum Haptic: Sendable {
    case selection
    case success
    case warning
    case error
    case impactLight

    public static let storageKey = "haptics"

    @MainActor public static func play(_ haptic: Haptic) {
        guard UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true else { return }
        switch haptic {
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impactLight: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
