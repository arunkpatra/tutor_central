import Testing
@testable import DesignSystem

/// Review minor: shadows were re-parsed from their CSS on every render. A token now carries its layers, parsed once
/// when the token is made (a `static let`), and drawing reads them.
struct ShadowTokenTests {
    @Test func aTokenCarriesItsParsedLayersForBothAppearances() {
        let raised = Tokens.shadowRaised
        let parsedDark = ShadowToken.parse(raised.dark)
        #expect(raised.layers(dark: true).drops == parsedDark.drops && raised.layers(dark: true).inset == parsedDark
            .inset)
        #expect(raised.layers(dark: false).drops == ShadowToken.parse(raised.light).drops)
        #expect(Tokens.shadowWell.layers(dark: false).drops.isEmpty && Tokens.shadowWell.layers(dark: true)
            .inset != nil)
    }
}
