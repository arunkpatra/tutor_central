import SwiftUI

/// Durations in seconds; the document writes milliseconds for the first four and seconds for the toasts.
public extension Tokens {
    static let press = 0.16
    static let panel = 0.24
    static let number = 0.5
    static let breathe = 1.6
    /// The launch screen's book fading into the first screen (P7-Launch-Fade).
    static let opening = 0.5
    static let toastStay = 5.0
    static let toastStayUndo = 8.0
    /// cubic-bezier(.2, .8, .2, 1) for every transition the system does not own.
    static let easeOut = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.2, y: 0.8),
        endControlPoint: UnitPoint(x: 0.2, y: 1)
    )
    static let pressScale: CGFloat = 0.97

    static let durations: [(String, Double)] = [
        ("press", press), ("panel", panel), ("number", number), ("breathe", breathe), ("opening", opening),
        ("toastStay", toastStay),
        ("toastStayUndo", toastStayUndo),
    ]
}
