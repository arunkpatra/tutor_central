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

    @Test func anAttendanceLinkPushesTheMarkRootOnMore() {
        let tabs = TabsState(selected: .fees)
        tabs.push(.payments)
        #expect(tabs.open(.attendance(date: "2026-10-05", classID: nil)))
        #expect(tabs.selected == .more && tabs.paths[.more] == [.attendance])
        // Another tab's stack is left alone.
        #expect(tabs.paths[.fees] == [.payments])
    }

    @Test func markAttendancePushesOnTheTabThatAskedAndComesBackToAnOpenMarkRoot() {
        let tabs = TabsState(selected: .today)
        tabs.showAttendance()
        #expect(tabs.paths[.today] == [.attendance])
        tabs.push(.history)
        // History's session opens the mark root already under it, not a second one.
        tabs.showAttendance()
        #expect(tabs.paths[.today] == [.attendance])
        tabs.select(.students)
        tabs.push(.classroom(UUID()))
        tabs.showAttendance()
        #expect(tabs.paths[.students]?.last == .attendance && tabs.paths[.students]?.count == 2)
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

    @Test func theAIRoutesPushOnTheTabThatAsked() {
        let tabs = TabsState()
        tabs.select(.more)
        tabs.push(.aiAssistant)
        tabs.push(.aiForm(.paper))
        #expect(tabs.paths[.more] == [.aiAssistant, .aiForm(.paper)])
        tabs.select(.today)
        tabs.push(.aiAssistant)
        #expect(tabs.paths[.today] == [.aiAssistant] && tabs.paths[.more]?.count == 2, "each tab keeps its own stack")
        let id = UUID()
        tabs.push(.aiResult(id))
        #expect(tabs.paths[.today]?.last == .aiResult(id))
        tabs.remove(.aiResult(id))
        #expect(tabs.paths[.today] == [.aiAssistant])
    }
}
