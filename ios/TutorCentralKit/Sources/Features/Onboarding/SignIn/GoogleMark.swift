import DesignSystem
import SwiftUI

/// The board's stand-in for Google's mark: a 20 pt ring, 2 pt text2 stroke, a "G" in 12 pt heavy text2. No Google
/// asset ships with the app.
struct GoogleMark: View {
    static var size: CGFloat {
        Tokens.iconButton
    }

    static var stroke: CGFloat {
        2
    }

    static var letter: CGFloat {
        12
    }

    var body: some View {
        Text("G")
            .font(.system(size: Self.letter, weight: .heavy))
            .foregroundStyle(Tokens.text2.color)
            .frame(width: Self.size, height: Self.size)
            .overlay(Circle().strokeBorder(Tokens.text2.color, lineWidth: Self.stroke))
            .accessibilityHidden(true)
    }
}
