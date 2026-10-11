import Data
import Domain
import Foundation
import Students
import Testing
import Today
@testable import AppShell

/// A student's This week "Today" (U35): the Today tab at its root, the batch's plan in view.
@MainActor struct OpenTodayTests {
    @Test func openTodaySelectsTheTabAndFocusesTheBatch() {
        let shell = ShellState()
        shell.tabs.select(.students)
        shell.tabs.paths[.today] = [.close(FakeClassesRepository.evening.id)]
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(),
            classes: FakeClassesRepository(), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        shell.today = TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace, counts: FakeCountsRepository(), register: register,
            attendance: FakeAttendanceRepository(), events: FakeEventsRepository(),
            tasks: TasksStore(
                workspace: FakeCentreRepository.meeraWorkspace, tasks: FakeTasksRepository(),
                now: { FakeCountsRepository.fixedNow }
            ),
            now: { FakeCountsRepository.fixedNow }
        )
        shell.openToday(batch: FakeClassesRepository.evening.id)
        #expect(shell.tabs.selected == .today)
        #expect(shell.tabs.paths[.today]?.isEmpty == true)
        #expect(shell.today?.focusBatch == FakeClassesRepository.evening.id)
    }
}
