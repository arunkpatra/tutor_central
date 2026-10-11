import Testing
@testable import DesignSystem

/// The Kit's Phase 10 rows (plan/phase-15-plan.md Task 11, decision 19).
struct KitPhase10Tests {
    @Test func theKitHasAPhase10SectionAfterPhase7() {
        #expect(Array(KitView.Section.allCases.suffix(2)) == [.phase10, .phase10Figures])
    }

    @Test func theRightOrWrongPairToggles() {
        #expect(RightWrongPair.toggled(nil, tapping: true) == true)
        #expect(RightWrongPair.toggled(true, tapping: true) == nil)
        #expect(RightWrongPair.toggled(true, tapping: false) == false)
    }
}
