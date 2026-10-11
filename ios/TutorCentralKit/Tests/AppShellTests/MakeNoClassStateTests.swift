import Data
import Domain
import Foundation
import Make
import Testing
@testable import AppShell

/// The review's R-app-2: the sheet's form for a student whose class is not set has a launch state.
@MainActor struct MakeNoClassStateTests {
    @Test func theNoClassSheetStateOpensTheSheetFormForRiyaWithoutAClass() {
        #expect(Fixtures.makeForms[.makeSheetNoClass] == .sheet)
        #expect(RootView.aiStates.contains(.makeSheetNoClass))
        let riya = Fixtures.register(for: .makeSheetNoClass).students.first { $0.id == FakeStudentsRepository.riya }
        #expect(riya != nil && riya?.classLevel == nil)
    }
}
