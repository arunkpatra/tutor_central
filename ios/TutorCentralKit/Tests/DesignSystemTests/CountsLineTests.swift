import Testing
@testable import DesignSystem

struct CountsLineTests {
    @Test func theWords() {
        #expect(CountsLine.text(present: 6, absent: 0) == (present: "6 present", absent: "0 absent"))
        #expect(CountsLine.text(present: 1, absent: 1) == (present: "1 present", absent: "1 absent"))
    }
}
