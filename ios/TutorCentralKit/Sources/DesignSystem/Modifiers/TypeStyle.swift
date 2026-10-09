import SwiftUI

/// Applies a type token: font (Dynamic Type), line height, tracking, upper-casing. Every text in the app goes through
/// it.
public struct TypeStyle: ViewModifier {
    let token: TypeToken
    /// Read here so a text size changed while the app runs redraws the text with the layout around it.
    @Environment(\.dynamicTypeSize) private var typeSize

    public func body(content: Content) -> some View {
        content
            .font(token.font(at: typeSize))
            .lineSpacing(token.lineSpacing)
            .kerning(token.kerning)
            .textCase(token.uppercase ? .uppercase : nil)
    }
}

public extension View {
    func typeStyle(_ token: TypeToken) -> some View {
        modifier(TypeStyle(token: token))
    }
}
