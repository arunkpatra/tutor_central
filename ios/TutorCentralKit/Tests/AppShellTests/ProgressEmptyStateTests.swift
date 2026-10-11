import Foundation
import Testing
@testable import AppShell

/// The review's R-app-9: Progress before the centre's first student has a launch state.
@MainActor struct ProgressEmptyStateTests {
    @Test func theEmptyProgressStateHasNoStudents() {
        #expect(Fixtures.progressStates.contains(.reportsProgressEmpty))
        #expect(Fixtures.register(for: .reportsProgressEmpty).students.isEmpty)
        #expect(RootView.reportsBoardState(.reportsProgressEmpty) == .progress)
    }
}
