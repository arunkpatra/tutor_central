import Testing
@testable import DesignSystem

struct NoteWellTests {
    @Test func theCounterReadsTheCountAndTurnsOverPastTheLimit() {
        #expect(NoteWell.counter(212, limit: 600) == ("212 of 600", false))
        #expect(NoteWell.counter(600, limit: 600) == ("600 of 600", false))
        #expect(NoteWell.counter(601, limit: 600) == ("601 of 600", true))
    }
}
