import Testing
@testable import DesignSystem

/// VoiceOver reads a formula in words (D102, "Phase 20 boards").
@Test func speaksAFormula() {
    #expect(MathSpeech.words("$\\frac{x}{4} - 2 = 1$") == "x over 4 minus 2 equals 1")
    #expect(MathSpeech.words("$\\sqrt{16}$ and $x^{2}$") == "square root of 16 and x squared")
    #expect(MathSpeech.words("Solve $3x + 5 = 20$.") == "Solve 3x plus 5 equals 20.")
    #expect(MathSpeech.words("$x^3$ and $\\alpha + \\beta$") == "x to the 3 and alpha plus beta")
    #expect(MathSpeech.words("$\\frac{2x + 1}{3} \\times 4$") == "2x plus 1 over 3 times 4")
    #expect(MathSpeech.words("No maths here.") == "No maths here.")
}

/// The app review's finding 1: a power of `\circ` is degrees, and a command is read whole (`\left` is not `\le` +
/// "ft").
@Test func degreesAndBracketsAreReadAsWords() {
    #expect(MathSpeech.words("$90^\\circ$") == "90 degrees")
    #expect(MathSpeech.words("$90^{\\circ}$") == "90 degrees")
    #expect(MathSpeech.words("$\\left(\\frac{3}{4}\\right)$") == "( 3 over 4 )")
    #expect(MathSpeech.words("$x \\le 5$") == "x less than or equal to 5")
}
