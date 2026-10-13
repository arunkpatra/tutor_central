import Foundation
import Testing
@testable import DesignSystem

/// Mathematics on the phone (D102): a text split into words and formulae by the rules the server's PDF shares
/// (tools/contract/maths-cases.json, copied here by bun contract).
@Test func splitsInlineAndDisplay() {
    #expect(MathSplit.runs("Solve $3x + 5 = 20$.") == [.text("Solve "), .inline("3x + 5 = 20"), .text(".")])
    #expect(MathSplit.runs("$$x = 1$$") == [.display("x = 1")])
}

@Test func anUnbalancedFormulaIsShownAsWritten() {
    #expect(MathSplit.runs("Solve $\\frac{x}{4 - 2 = 1") == [.text("Solve $\\frac{x}{4 - 2 = 1")])
}

@Test func aNonLatinTextIsDrawnAsWords() {
    #expect(MathSplit.runs("$\\text{आधा} = \\frac{1}{2}$") == [.text("आधा"), .inline(" = \\frac{1}{2}")])
}

@Test func aSheetWithNoDollarIsPlainText() {
    #expect(MathSplit.runs("Name the reactants.") == [.text("Name the reactants.")])
    #expect(MathSplit.hasMaths("Name the reactants.") == false)
    #expect(MathSplit.hasMaths("Solve $x = 1$") == true)
}

private struct MathsCase: Decodable {
    let name: String
    let text: String
    let runs: [Run]
    struct Run: Decodable {
        let kind: String
        let text: String
    }
}

@Test func everySharedCaseSplitsAsTheServerSplitsIt() throws {
    let url = try #require(Bundle.module.url(forResource: "maths-cases", withExtension: "json", subdirectory: "Cases"))
    let cases = try JSONDecoder().decode([MathsCase].self, from: Data(contentsOf: url))
    #expect(cases.count >= 10)
    for c in cases {
        let expected: [MathRun] = c.runs.map { run in
            switch run.kind {
            case "inline": .inline(run.text)
            case "display": .display(run.text)
            default: .text(run.text)
            }
        }
        #expect(MathSplit.runs(c.text) == expected, "\(c.name)")
    }
}

@Test func aFormulasEdgeSpacesBecomeWordSpaces() {
    #expect(MathText.spaced(MathSplit.runs("$3 \\text{ सेब} + 2$")) == [
        .inline("3"),
        .text(" सेब"),
        .text(" "),
        // A formula that opens on an operator keeps an operator's space after it.
        .inline("+\\> 2"),
    ])
    // A relation keeps its own space.
    #expect(MathText.spaced(MathSplit.runs("आधा $= \\frac{1}{2}$")) == [.text("आधा "), .inline("= \\frac{1}{2}")])
    #expect(MathText.spaced(MathSplit.runs("Half is $x$ here")) == [.text("Half is "), .inline("x"), .text(" here")])
}

/// A formula in a heavy type token is bold, digits too: `\bm` is bold italic, which has no digits, so a number takes
/// `\mathbf` inside it (the board view's 2⁵ was drawn regular beside its bold words, hand run 7).
@Test func aHeavyFormulaIsBoldDigitsAndAll() {
    #expect(MathText.weighted("2^5", weight: 800) == "\\bm{\\mathbf{2}^\\mathbf{5}}")
    #expect(MathText.weighted("x + 9 = 25", weight: 800) == "\\bm{x + \\mathbf{9} = \\mathbf{25}}")
    #expect(MathText
        .weighted("\\frac{3}{8} = 0.38", weight: 600) == "\\bm{\\frac{\\mathbf{3}}{\\mathbf{8}} = \\mathbf{0.38}}")
    #expect(MathText.weighted("2^5", weight: 400) == "2^5")
}

/// The app review's finding 4: a formula that opens on a sign keeps it a sign (`−7`); only an operator written with a
/// space after it (the words' `+ 2`) is spaced as an operator.
@Test func aLeadingSignStaysASign() {
    #expect(MathText.spaced(MathSplit.runs("Add $-7 + 3$.")) == [.text("Add "), .inline("-7 + 3"), .text(".")])
    #expect(MathText.spaced(MathSplit.runs("$-\\frac{1}{2}$")) == [.inline("-\\frac{1}{2}")])
}

/// The app review's finding 2: a key's answer is drawn at 600, the board's weight, digits and all.
@Test func aKeysAnswerFormulaIsBold() {
    #expect(MathText.weighted("x = 5", weight: KeyRow.answerWeight) == "\\bm{x = \\mathbf{5}}")
}
