import Testing
import UIKit
@testable import DesignSystem

struct TypeTokenTests {
    /// The design's line height is the font's own plus the spacing, not the point size plus it.
    @Test func lineSpacingFillsTheFontsOwnLineHeightUpToTheDesignsLine() {
        for token in Tokens.types {
            let natural = UIFont.systemFont(ofSize: token.size, weight: token.weight.uiKit).lineHeight
            #expect(abs(max(natural, token.line) - (natural + token.lineSpacing)) < 0.001, "\(token.name)")
        }
    }
}
