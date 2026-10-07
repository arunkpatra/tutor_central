import SwiftUI

/// The document's two-value rows are split: `rowPadding` 14 × 16, `tabBarInset` 16 × 34, and `cardPadding` with its
/// compact 14.
public extension Tokens {
    static let inline: CGFloat = 8
    static let fieldGap: CGFloat = 6
    static let rowGapInner: CGFloat = 2
    static let tileGap: CGFloat = 10
    static let sectionGap: CGFloat = 18
    static let sectionHeaderGap: CGFloat = 10
    static let cardPadding: CGFloat = 18
    static let cardPaddingCompact: CGFloat = 14
    static let rowPaddingVertical: CGFloat = 14
    static let rowPaddingHorizontal: CGFloat = 16
    static let pageSide: CGFloat = 20
    static let pageTop: CGFloat = 62
    static let tabBarInsetSide: CGFloat = 16
    static let tabBarInsetBottom: CGFloat = 34
    static let contentBottom: CGFloat = 120
    static let heroInset: CGFloat = 24
    static let heroTop: CGFloat = 80
    static let heroLead: CGFloat = 72
    static let rowPaddingDense: CGFloat = 12
    static let hairline: CGFloat = 1
    static let iconTab: CGFloat = 22
    static let iconButton: CGFloat = 20
    static let iconInline: CGFloat = 16

    static let spacings: [(String, CGFloat)] = [
        ("inline", inline), ("fieldGap", fieldGap), ("rowGapInner", rowGapInner), ("tileGap", tileGap),
        ("sectionGap", sectionGap), ("sectionHeaderGap", sectionHeaderGap), ("cardPadding", cardPadding),
        ("cardPaddingCompact", cardPaddingCompact), ("rowPaddingVertical", rowPaddingVertical),
        ("rowPaddingHorizontal", rowPaddingHorizontal), ("pageSide", pageSide), ("pageTop", pageTop),
        ("tabBarInsetSide", tabBarInsetSide), ("tabBarInsetBottom", tabBarInsetBottom),
        ("contentBottom", contentBottom), ("heroInset", heroInset), ("heroTop", heroTop), ("heroLead", heroLead),
        ("rowPaddingDense", rowPaddingDense), ("hairline", hairline), ("iconTab", iconTab), ("iconButton", iconButton),
        ("iconInline", iconInline),
    ]
}
