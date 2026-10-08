import Data
import Domain
import Foundation
import Students
import Testing
import Today
@testable import AppShell

/// Review, Important 2: leaving the tabs (sign-out) forgets where the tutor was, so the next sign-in, perhaps by
/// another tutor, starts at Today with nothing pushed and a fresh Today store.
@MainActor struct ShellStateTests {
    func today(_ workspace: Workspace) -> TodayStore {
        TodayStore(
            workspace: workspace, counts: FakeCountsRepository(),
            register: RegisterStore(
                workspace: workspace, students: FakeStudentsRepository(), classes: FakeClassesRepository(), cache: nil,
                now: { Fixtures.now }
            ),
            attendance: FakeAttendanceRepository(), events: FakeEventsRepository(),
            tasks: TasksStore(workspace: workspace, tasks: FakeTasksRepository(), now: { Fixtures.now }),
            now: { Fixtures.now }
        )
    }

    @Test func signingOutResetsTheTabsAndToday() {
        let shell = ShellState()
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace))
        shell.tabs.select(.fees)
        shell.tabs.push(.settings)
        shell.today = today(Fixtures.meeraWorkspace)
        shell.sessionChanged(.signedOut)
        #expect(shell.tabs.selected == .today && (shell.tabs.paths[.fees] ?? []).isEmpty && shell.today == nil)
    }

    @Test func anotherCentreAlsoStartsFresh() {
        let shell = ShellState()
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace))
        shell.today = today(Fixtures.meeraWorkspace)
        let other = Workspace(
            user: Fixtures.meeraWorkspace.user,
            centre: Centre(id: UUID(), name: "Other", whatsappNumber: nil),
            profile: Fixtures.meeraWorkspace.profile
        )
        shell.sessionChanged(.ready(other))
        #expect(shell.today == nil)
    }

    @Test func theSameCentreKeepsItsPlace() {
        let shell = ShellState()
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace))
        shell.tabs.select(.fees)
        shell.today = today(Fixtures.meeraWorkspace)
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace))
        #expect(shell.tabs.selected == .fees && shell.today != nil)
    }

    @Test func signingOutForgetsTheRegister() {
        let shell = ShellState()
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace))
        shell.register = RegisterStore(
            workspace: Fixtures.meeraWorkspace,
            students: FakeStudentsRepository(),
            classes: FakeClassesRepository(),
            cache: nil,
            now: { Fixtures.now }
        )
        shell.sessionChanged(.signedOut)
        #expect(shell.register == nil)
    }
}
