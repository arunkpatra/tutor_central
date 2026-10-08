import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct TabsStateTests {
    @Test func pushingAndPoppingOnTheStudentsTab() {
        let tabs = TabsState(selected: .students)
        tabs.push(.classes)
        tabs.push(.classroom(UUID()))
        #expect(tabs.paths[.students]?.count == 2)
        tabs.select(.students)
        #expect(tabs.paths[.students] == [])
    }
}
