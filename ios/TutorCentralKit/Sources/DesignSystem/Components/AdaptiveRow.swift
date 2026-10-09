import SwiftUI

/// When a row gives up its side-by-side shape (guidelines.md, "Dynamic Type"): only at the accessibility sizes, where a
/// title and its trailing value no longer fit one line without breaking words.
public enum TypeSizeLayout {
    public static func stacks(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}

/// A row at the usual sizes; at the accessibility sizes a leading column the full width, so a trailing value wraps
/// under its title instead of squeezing it. One layout that changes kind (`AnyLayout`), so the children keep their
/// identity and a field its focus. At the usual sizes it is exactly the `HStack` it replaces: same alignment, same
/// spacing, and an `AdaptiveSpacer` where the `Spacer` was (a plain `Spacer` would open a gap in the column).
public struct AdaptiveRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var size
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let stackedSpacing: CGFloat
    let content: Content

    /// `spacing` nil is the system's, as `HStack`'s default. `stackedSpacing` is the gap in the column (a title over
    /// its value by default; Today's tiles use `tileGap`).
    public init(
        alignment: VerticalAlignment = .center, spacing: CGFloat? = Tokens.rowPaddingDense,
        stackedSpacing: CGFloat = Tokens.rowGapInner, @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.stackedSpacing = stackedSpacing
        self.content = content()
    }

    public var body: some View {
        let stacks = TypeSizeLayout.stacks(size)
        let layout = stacks
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: stackedSpacing))
            : AnyLayout(HStackLayout(alignment: alignment, spacing: spacing))
        layout { content }
            .frame(maxWidth: stacks ? .infinity : nil, alignment: .leading)
    }
}

/// The `Spacer` of an `AdaptiveRow`: the row's flexible gap at the usual sizes, nothing in the column.
public struct AdaptiveSpacer: View {
    @Environment(\.dynamicTypeSize) private var size
    let minLength: CGFloat?

    public init(minLength: CGFloat? = nil) {
        self.minLength = minLength
    }

    public var body: some View {
        if !TypeSizeLayout.stacks(size) {
            Spacer(minLength: minLength)
        }
    }
}

/// The vertical padding a fixed-height row needs once it grows at the accessibility sizes; none at the usual sizes,
/// where the row keeps the height it is drawn at.
public struct GrowsWithText: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size

    public func body(content: Content) -> some View {
        content.padding(.vertical, TypeSizeLayout.stacks(size) ? Tokens.inline : 0)
    }
}

public extension View {
    func growsWithText() -> some View {
        modifier(GrowsWithText())
    }
}

/// A trailing column of a row (a fee over its status): right-aligned beside the title, left-aligned under it at the
/// accessibility sizes.
public struct TrailingColumn<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var size
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = Tokens.rowGapInner, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: TypeSizeLayout.stacks(size) ? .leading : .trailing, spacing: spacing) { content }
    }
}
