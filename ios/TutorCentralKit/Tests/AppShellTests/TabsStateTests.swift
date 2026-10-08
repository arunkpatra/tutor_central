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
    }

    @Test func aRouteThatCannotShowIsTakenOffItsStack() {
        let tabs = TabsState(selected: .today)
        let missing = UUID()
        #expect(tabs.open(.student(missing)))
        tabs.remove(.student(missing))
        #expect(tabs.paths[.students] == [] && tabs.selected == .students)
    }

    @Test func anAttendanceLinkOpensTheTab() {
        let tabs = TabsState(selected: .today)
        tabs.push(.settings)
        #expect(tabs.open(.attendance(date: "2026-10-05", classID: nil)))
        #expect(tabs.selected == .attendance && tabs.paths[.attendance] == [])
    }

    @Test func anEventLinkOpensItOnTheMoreTab() {
        let tabs = TabsState(selected: .today)
        let id = UUID()
        #expect(tabs.open(.event(id)))
        // The event's route is the schedule with its Edit sheet: one screen, not a schedule under a schedule.
        #expect(tabs.selected == .more && tabs.paths[.more] == [.event(id)])
    }

    @Test func aFeesLinkOpensTheTab() {
        let tabs = TabsState(selected: .today)
        tabs.push(.settings)
        #expect(tabs.open(.fees(month: "2026-09")))
        #expect(tabs.selected == .fees && tabs.paths[.fees] == [])
        #expect(RootView.linkMonth("2026-09") == Period(year: 2026, month: 9))
        #expect(RootView.linkMonth("2026-13") == nil && RootView.linkMonth(nil) == nil && RootView
            .linkMonth("x") == nil)
    }
}
