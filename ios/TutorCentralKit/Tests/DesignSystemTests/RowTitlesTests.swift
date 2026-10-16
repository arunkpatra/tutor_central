import Testing
@testable import DesignSystem

struct RowTitlesTests {
    @Test func aTitleWithAFormulaIsDrawnAsMaths() {
        #expect(RowTitles.drawsMaths("Solve $\\frac{x}{4} - 2 = 1$ and check your answer.", match: nil))
    }

    @Test func wordsAndASearchMatchStayText() {
        let name = "Riya Sharma"
        #expect(!RowTitles.drawsMaths(name, match: nil))
        #expect(!RowTitles.drawsMaths("Solve $x + 1 = 2$", match: name.startIndex ..< name.endIndex))
        #expect(!RowTitles.drawsMaths("Costs $5", match: nil))
    }
}
