import Data
import Domain
import Foundation
import Testing
@testable import AppShell

/// Hand run 8: Mark from a photo's intro has a launch state, Dev with his exam's mock as the preset.
@MainActor struct CheckIntroMockStateTests {
    @Test func markFromAPhotosIntroOpensWithTheMockAsItsPreset() {
        #expect(RootView.initialRoutes(for: .checkIntroMock) == [.checkPaper(RootView.checkVisit)])
        #expect(Fixtures.checkPreset(for: .checkIntroMock)?.studentID == FakeStudentsRepository.dev)
        #expect(Fixtures.checkPreset(for: .checkIntroMock)?.mark.test == "Science unit test 3 · mock")
        #expect(Fixtures.checkPreset(for: .checkIntro) == nil)
    }
}
