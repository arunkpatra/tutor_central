import Testing
import UIKit
@testable import DesignSystem

/// SwiftMath draws a formula into an image at the type's size and colour (D102); nonsense draws nothing, so the
/// text is shown as written.
@Test @MainActor func rendersAFractionAndRefusesNonsense() throws {
    let fraction = try #require(MathRenderer.rendered(
        latex: "\\frac{x}{4}",
        pointSize: 15,
        color: .white,
        display: false
    ))
    #expect(fraction.image.size.width > 0)
    #expect(fraction.image.size.height > 15)
    #expect(fraction.descent > 0)
    #expect(MathRenderer.image(latex: "\\frac{x}{4", pointSize: 15, color: .white, display: false) == nil)
}

@Test @MainActor func aFormulaGrowsWithItsSize() throws {
    let small = try #require(MathRenderer.rendered(latex: "x^{2} + 1", pointSize: 17, color: .white, display: false))
    let large = try #require(MathRenderer.rendered(latex: "x^{2} + 1", pointSize: 34, color: .white, display: false))
    #expect(large.image.size.height > small.image.size.height * 1.6)
}

/// At the largest text sizes a formula wider than its line is drawn smaller to fit, never cut off.
@Test @MainActor func aFormulaWiderThanItsLineIsDrawnToFit() throws {
    let latex = "2(x - 3) = x + 4"
    let full = try #require(MathRenderer.rendered(latex: latex, pointSize: 60, color: .white, display: true))
    #expect(full.image.size.width > 200)
    let fitted = try #require(MathRenderer.rendered(
        latex: latex, pointSize: 60, color: .white, display: true, fitting: 200
    ))
    #expect(fitted.image.size.width <= 200)
    #expect(fitted.image.size.width > 150)
    let narrow = try #require(MathRenderer.rendered(
        latex: "x", pointSize: 17, color: .white, display: true, fitting: 200
    ))
    #expect(narrow.image.size == MathRenderer.rendered(latex: "x", pointSize: 17, color: .white, display: true)?
        .image.size)
}
