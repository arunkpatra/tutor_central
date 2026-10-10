import Foundation
import Testing
@testable import AppShell

/// The 10.3 plan states (Phase 12).
extension LaunchStateTests {
    @Test func thePlansStatesAreNamedAsTheBoardsNameThem() {
        for name in [
            "today-scrolled", "today-planning", "today-line-menu", "today-plan-changed", "today-plan-change",
            "today-no-batch",
        ] {
            #expect(LaunchState(rawValue: name) != nil, "\(name)")
        }
        #expect(LaunchState(rawValue: "today-no-class") == nil)
    }
}
