import SwiftUI

/// Applies a type token: font (Dynamic Type), line height, tracking, upper-casing. Every text in the app goes through
/// it.
public struct TypeStyle: ViewModifier {
    let token: TypeToken

    public func body(content: Content) -> some View {
        content
            .font(token.font)
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
