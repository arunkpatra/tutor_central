import SwiftUI

public extension View {
    /// A sheet at the height its board draws (a fraction of the screen), draggable to full. At the accessibility sizes
    /// it opens full and scrolls, since its fields no longer fit the drawn height; the choice follows the text size
    /// only, never the keyboard, so typing never rebuilds the sheet.
    func boardDetents(_ fraction: CGFloat) -> some View {
        modifier(BoardDetents(fraction: fraction))
    }
}

private struct BoardDetents: ViewModifier {
    let fraction: CGFloat
    @Environment(\.dynamicTypeSize) private var size

    func body(content: Content) -> some View {
        if TypeSizeLayout.stacks(size) {
            ScrollView { content }.presentationDetents([.large])
        } else {
            content.presentationDetents([.fraction(fraction), .large])
        }
    }
}
