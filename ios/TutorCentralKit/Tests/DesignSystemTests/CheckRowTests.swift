import Testing
@testable import DesignSystem

struct CheckRowTests {
    @Test func tappingASegmentSetsItAndTappingItAgainClears() {
        #expect(CheckRow.toggled(nil, tapping: true) == true)
        #expect(CheckRow.toggled(true, tapping: true) == nil)
        #expect(CheckRow.toggled(true, tapping: false) == false)
        #expect(CheckRow.toggled(false, tapping: false) == nil)
    }
}
