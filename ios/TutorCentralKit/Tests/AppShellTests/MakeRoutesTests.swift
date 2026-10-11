import Artefacts
import Data
import Domain
import Foundation
import Make
import Testing
@testable import AppShell

/// Make something's routes (plan/phase-15-plan.md Task 7).
struct MakeRoutesTests {
    @MainActor @Test func makeOpensFromMoreAndItsKindsOpenTheirForms() {
        #expect(RootView.initialRoutes(for: .make) == [.make] && RootView.initialRoutes(for: .makeEmpty) == [.make])
        #expect(RootView.tab(for: .make) == .more)
        #expect(RootView.formRoute(for: .paper) == .aiForm(.paper))
        #expect(RootView.formRoute(for: .worksheet) == .aiForm(.worksheet))
        #expect(RootView.formRoute(for: .sheet) == .makeForm(.sheet))
        #expect(RootView.formRoute(for: .noteToParent) == .makeForm(.noteToParent))
        #expect(LaunchState(rawValue: "make-empty") == .makeEmpty && LaunchState(rawValue: "ai-assistant") == nil)
    }
}
