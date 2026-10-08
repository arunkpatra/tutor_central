import UIKit

/// The keyboard, from a view that does not own the field holding it.
@MainActor
public enum Keyboard {
    /// Puts the keyboard away, so what a tap changes below the fields is seen (an error row, the creating card).
    public static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
