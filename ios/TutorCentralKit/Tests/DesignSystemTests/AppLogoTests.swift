import Testing
import UIKit
@testable import DesignSystem

/// The tile beside the name on sign-in (P23-SignIn, D122): the brand kit's AppMark on `logoTile`, flat.
struct AppLogoTests {
    @Test func drawsTheKitsMark() {
        #expect(AppLogo.image == "AppMark")
        #expect(UIImage(named: AppLogo.image, in: MarkImages.bundle, with: nil) != nil)
    }

    @Test func theMarkIsTheIconsShareOfTheTile() {
        #expect(AppLogo.size == 56)
        #expect(AppLogo.mark == 33)
    }

    @Test func theTileFollowsTheGround() {
        #expect(Tokens.logoTile.dark == RGBA(css: "#FFAB38"))
        #expect(Tokens.logoTile.light == RGBA(css: "#131110"))
        #expect(Tokens.logoMark.dark == RGBA(css: "#1F1B17"))
        #expect(Tokens.logoMark.light == RGBA(css: "#FFAB38"))
    }
}
