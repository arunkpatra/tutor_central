import Testing
@testable import DesignSystem

/// The plan's parts (P10-Today-Plan, components.md "Phase 10 parts" 10.3): their words; the views are proven by the
/// pictures.
struct PlanPartsTests {
    @Test func theChecklistCountReads() {
        #expect(LineChecklist.count(done: 2, total: 5) == "2 of 5")
        #expect(LineChecklist.count(done: 5, total: 5) == "5 of 5")
    }

    @Test func aReadyMarkNamesItsState() {
        #expect(ReadyMark(name: "Set 1", state: .made).accessibilityWords == "Set 1, made")
        #expect(ReadyMark(name: "Sheet 1", state: .onItsWay).accessibilityWords == "Sheet 1, on its way")
        #expect(ReadyMark(name: "Checks", state: .notMade).accessibilityWords == "Checks, not made")
    }

    @Test func theRestLineJoinsItsBitsWithTheMiddleDot() {
        let bits = [LineBit(text: "Practise set 1", struck: false), LineBit(text: "Check 3", struck: true)]
        #expect(PlanLineRow.restText(bits) == "Practise set 1 · Check 3")
    }

    @Test func theMenuOffersEveryOtherGroup() {
        #expect(LineMenu.moveTargets(groups: [1, 2, 3], current: 2) == [1, 3])
        #expect(LineMenu.moveTargets(groups: [1], current: 1).isEmpty)
    }
}
