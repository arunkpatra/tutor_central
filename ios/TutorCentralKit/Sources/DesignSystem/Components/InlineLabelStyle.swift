import SwiftUI

/// A symbol at `iconInline` before its text, `fieldGap` apart (an error line, a note).
public struct InlineLabelStyle: LabelStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.fieldGap) {
            configuration.icon.font(.system(size: Tokens.iconInline))
            configuration.title
        }
    }
}
