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

    @Test func aStudentLinkOpensTheDetailOnTheStudentsTab() {
        let tabs = TabsState(selected: .today)
        let id = UUID()
        #expect(tabs.open(.student(id)))
        #expect(tabs.selected == .students && tabs.paths[.students] == [.student(id)])
        #expect(!tabs.open(.fees(month: nil)))
    }

    @Test func aRouteThatCannotShowIsTakenOffItsStack() {
        let tabs = TabsState(selected: .today)
        let missing = UUID()
        #expect(tabs.open(.student(missing)))
        tabs.remove(.student(missing))
        #expect(tabs.paths[.students] == [] && tabs.selected == .students)
    }
}
