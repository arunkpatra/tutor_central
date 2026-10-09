import SwiftUI

/// The app's own motion under Reduce Motion: none, so a change lands at once. The system's own (sheets, pushes)
/// follows the device. Press, toasts and the breathing skeletons read the setting where they animate.
public enum ReducedMotion {
    public static func animation(_ animation: Animation, reduce: Bool) -> Animation? {
        reduce ? nil : animation
    }
}
