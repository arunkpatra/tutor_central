import Foundation
import Testing
@testable import Domain

/// The price sheet reads api/models.json (D67), so the budget is priced by the models the API calls.
struct PriceSheetTests {
    @Test func thePriceSheetReadsTheModelTable() throws {
        let sheet = try PriceSheet.load()
        #expect(sheet.rupeesPerDollar == 85)
        let mock = ArtefactRequest.mock(
            group: 1, itemID: UUID(), title: "Unit test", portions: [], pattern: .default(for: .eight),
            classLevel: .eight, subject: "Science"
        )
        #expect(sheet.model(for: mock) == "claude-sonnet-5-5")
        let eight = ArtefactRequest.sheet(
            group: 1, skills: [], classLevel: .eight, subject: "Science", questions: 8, forHomework: true
        )
        let two = ArtefactRequest.sheet(
            group: 1, skills: [], classLevel: .two, subject: "Mathematics", questions: 8, forHomework: true
        )
        #expect(sheet.model(for: eight) == "claude-sonnet-5-5")
        #expect(sheet.model(for: two) == "claude-haiku-5-5")
        #expect(sheet.price("claude-haiku-5-5")?.input == 0.10)
        #expect(sheet.price("claude-opus-5-5")?.output == 20)
    }
}
