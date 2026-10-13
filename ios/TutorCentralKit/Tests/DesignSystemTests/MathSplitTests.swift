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
