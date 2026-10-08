import Data
import Domain
import Testing
@testable import AppShell

struct LaunchStateTests {
    @Test func readsTheStateArgument() {
        #expect(LaunchState.fromArguments(["app", "--state", "kit"]) == .kit)
        #expect(LaunchState.fromArguments(["app", "--state", "kit-surfaces"]) == .kitSurfaces)
        #expect(LaunchState.fromArguments(["app"]) == nil)
        #expect(LaunchState.fromArguments(["app", "--state"]) == nil)
    }

    @Test func everyStateHasAKebabCaseNameForTheShotsTool() {
        for state in LaunchState.allCases {
            #expect(state.rawValue.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" }, "\(state.rawValue)")
        }
    }

    @MainActor @Test func everyBoardStateHasAFixture() {
        for state in LaunchState.allCases where state != .placeholder {
            _ = Fixtures.dependencies(for: state)
            _ = Fixtures.initialState(for: state)
        }
        #expect(Fixtures.initialState(for: .signin) == .signedOut)
        #expect(Fixtures.initialState(for: .onboarding) == .needsOnboarding(FakeAuthRepository.meera))
        #expect(Fixtures.initialState(for: .todayEmpty) == .ready(Fixtures.meeraWorkspace))
    }

    @MainActor @Test func theStudentsStatesStartReadyOnTheStudentsTabWithTheirRegister() async throws {
        let states: [LaunchState] = [
            .studentsEmpty,
            .studentsFew,
            .students,
            .studentsSearching,
            .studentsFiltered,
            .studentsAddMenu,
        ]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students)
        }
        let centre = Fixtures.meeraWorkspace.centre.id
        let october = Period(year: 2026, month: 10)
        let deps = Fixtures.dependencies(for: .students)
        #expect(try await deps.students.students(centre: centre, period: october).count == 10 && !deps.cachesRegister)
        let few = Fixtures.dependencies(for: .studentsFew)
        #expect(try await few.students.students(centre: centre, period: october).count == 3)
        #expect(try await few.classes.classes(centre: centre).isEmpty)
        let none = Fixtures.dependencies(for: .studentsEmpty)
        #expect(try await none.students.students(centre: centre, period: october).isEmpty)
    }

    @MainActor @Test func theNewStudentStatesStartReadyOnTheStudentsTab() async throws {
        for state in [LaunchState.studentNew, .studentNewFilled, .studentNewInvalid] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students && RootView.studentsBoardState(state) != nil)
            let classes = try await Fixtures.dependencies(for: state).classes
                .classes(centre: Fixtures.meeraWorkspace.centre.id)
            #expect(classes.count == 2)
        }
    }

    @MainActor @Test func theStudentDetailStatesOpenAkshitaOnTheStudentsTab() async throws {
        let states: [LaunchState] = [
            .student,
            .studentArchived,
            .studentArchiveConfirm,
            .studentDeleteConfirm,
            .studentEdit,
        ]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students)
            #expect(RootView.initialRoutes(for: state) == [.student(FakeStudentsRepository.akshita)])
        }
        #expect(RootView.initialRoutes(for: .settings) == [.settings] && RootView.initialRoutes(for: .students).isEmpty)
        let archived = try await Fixtures.dependencies(for: .studentArchived).students
            .students(centre: Fixtures.meeraWorkspace.centre.id, period: Period(year: 2026, month: 10))
        #expect(archived.first { $0.id == FakeStudentsRepository.akshita }?.isArchived == true)
    }

    @MainActor @Test func theClassesStatesOpenTheClassesList() async throws {
        let states: [LaunchState] = [.classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students && RootView.initialRoutes(for: state) == [.classes])
        }
        #expect(RootView.classesBoardState(.classNew) == .newClass && RootView.classesBoardState(.classes) == nil)
        let empty = Fixtures.dependencies(for: .classesEmpty)
        #expect(try await empty.classes.classes(centre: Fixtures.meeraWorkspace.centre.id).isEmpty)
    }
}
