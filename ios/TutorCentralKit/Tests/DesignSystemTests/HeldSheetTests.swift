import Testing
@testable import DesignSystem

struct HeldSheetTests {
    @Test func theHeldSheetReadsAsTheBoard() {
        #expect(HeldSheet.sheetTitle == "Held" && HeldSheet.heading == "Held for this week")
        #expect(HeldSheet.sendNow == "Send it now" && HeldSheet.keep == "Keep it for next week")
    }
}
