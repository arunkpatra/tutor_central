import Testing
@testable import DesignSystem

/// U17: the note's and the typed scheme's counter reads as P6-Form-ProgressNote draws it; the Kit's stays.
struct NotesWellTests {
    @Test func theCounterReadsSlashAndNoGroupingAtTheNotesLimit() {
        #expect(MultilineWell.counterText(135, limit: 2000, slashed: true) == "135 / 2000")
        #expect(MultilineWell.counterText(80, limit: 2000, slashed: false) == "80 of 2,000")
    }
}
