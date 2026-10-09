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

    /// The size follows the text size it is given, so a change made while the app runs redraws every text at once
    /// (the layout and the type moved apart when the font read the app's size only once).
    @Test func theScaledSizeFollowsTheGivenTextSize() {
        #expect(Tokens.body.scaledSize(at: .large) == 17)
        #expect(Tokens.body.scaledSize(at: .accessibility3) > 30)
        #expect(Tokens.body.scaledSize(at: .xSmall) < 17)
    }
}
