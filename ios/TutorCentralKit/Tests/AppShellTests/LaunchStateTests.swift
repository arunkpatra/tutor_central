import Data
import Domain
import Foundation
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

    @MainActor @Test func theClassDetailStatesOpenClassTenMaths() {
        for state in [LaunchState.classDetail, .classAddMembers] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .students)
            #expect(RootView.initialRoutes(for: state) == [.classroom(FakeClassesRepository.maths.id)])
        }
        #expect(RootView.classDetailBoardState(.classAddMembers) == .addMembers)
    }

    @MainActor @Test func theAttendanceStatesOpenTheTab() async throws {
        let states: [LaunchState] = [
            .attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaved, .attendanceAlert,
            .attendancePast, .attendanceEmpty,
        ]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .attendance)
        }
        #expect(RootView.attendanceBoardState(.attendanceClassMenu) == .classMenu)
        #expect(RootView.attendanceBoardState(.attendanceAlert) == .alert)
        let centre = Fixtures.meeraWorkspace.centre.id
        let october = Period(year: 2026, month: 10)
        // Saved and the alert save for real on the boards' clock, 18:32 (P4-Attendance-Mark-Saved).
        let saved = Fixtures.dependencies(for: .attendanceSaved)
        #expect(try await saved.attendance.sessions(centre: centre, month: october).first?.date.day == 6)
        #expect(DayHeading.india.component(.minute, from: saved.now()) == 32)
        let fresh = Fixtures.dependencies(for: .attendance)
        #expect(try await fresh.attendance.sessions(centre: centre, month: october).first?.date.day == 6)
        let empty = Fixtures.dependencies(for: .attendanceEmpty)
        #expect(try await empty.students.students(centre: centre, period: october).isEmpty)
    }

    @MainActor @Test func theHistoryStatesPushOnTheAttendanceTab() {
        for state in [LaunchState.history, .historyByStudent, .historyEmpty] {
            #expect(RootView.tab(for: state) == .attendance && RootView.initialRoutes(for: state) == [.history])
        }
        #expect(RootView.initialRoutes(for: .historyStudent) == [
            .history,
            .historyStudent(FakeAttendanceRepository.hemanth),
        ])
        #expect(RootView.historyBoardState(.historyByStudent) == .byStudent && RootView
            .historyBoardState(.history) == nil)
    }

    @MainActor @Test func theScheduleStatesPushOnTheMoreTab() {
        for state in [
            LaunchState.schedule,
            .scheduleDay,
            .eventNew,
            .eventEdit,
            .eventEditKeyboard,
            .eventDeleteConfirm,
        ] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.schedule])
        }
        #expect(RootView.scheduleBoardState(.scheduleDay) == .saturday)
        #expect(RootView.scheduleBoardState(.eventDeleteConfirm) == .deleteConfirm)
        #expect(RootView.scheduleBoardState(.eventEditKeyboard) == .editEventKeyboard)
        #expect(RootView.scheduleBoardState(.schedule) == nil)
    }

    @MainActor @Test func theTasksStatesPushOnTheMoreTab() async throws {
        for state in [LaunchState.tasks, .tasksEmpty] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.tasks])
        }
        let centre = Fixtures.meeraWorkspace.centre.id
        #expect(try await Fixtures.dependencies(for: .tasksEmpty).tasks.tasks(centre: centre).isEmpty)
        #expect(try await Fixtures.dependencies(for: .tasks).tasks.tasks(centre: centre).count == 4)
    }

    @MainActor @Test func theMoreAndTodayStatesStartReady() {
        for state in [LaunchState.more, .today, .todayEvening, .todayNoClass, .todayAddingTask, .tasks, .tasksEmpty] {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
        }
        #expect(RootView.tab(for: .more) == .more && RootView.initialRoutes(for: .tasks) == [.tasks])
        #expect(RootView.tab(for: .tasks) == .more && RootView.tab(for: .today) == nil, "Today is the default tab")
        #expect(Fixtures.clock(for: .todayNoClass) == DayHeading.india.date(from: DateComponents(
            year: 2026, month: 10, day: 10, hour: 9, minute: 30
        )))
    }

    @MainActor @Test func theFeesStatesOpenTheTab() async throws {
        let states: [LaunchState] = [
            .feesEmpty, .fees, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate, .feesGenerateNothing,
            .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind, .feesWaive,
        ]
        for state in states {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.workspace(for: state)))
            #expect(RootView.tab(for: state) == .fees)
        }
        #expect(RootView.feesBoardState(.feesDue) == .due && RootView.feesBoardState(.feesMarkedPaid) == .markedPaid)
        #expect(RootView.feesBoardState(.fees) == nil)
        let centre = Fixtures.meeraWorkspace.centre.id
        let october = Period(year: 2026, month: 10)
        #expect(try await Fixtures.dependencies(for: .feesEmpty).fees.invoices(centre: centre, month: october).isEmpty)
        #expect(try await Fixtures.dependencies(for: .fees).fees.dueBefore(centre: centre, month: october).count == 1)
        #expect(Fixtures.workspace(for: .feesPayee).centre.payments.needsConfirmation)
        #expect(Fixtures.workspace(for: .feesEmpty).centre.payments.upiID == nil)
        #expect(!Fixtures.workspace(for: .fees).centre.payments.needsConfirmation)
    }

    @MainActor @Test func theStudentFeesStatesOpenHemanth() {
        let hemanth = FakeAttendanceRepository.hemanth
        #expect(RootView.tab(for: .studentFeesDue) == .students && RootView.tab(for: .studentFees) == .students)
        #expect(RootView.initialRoutes(for: .studentFeesDue) == [.student(hemanth)])
        #expect(RootView.initialRoutes(for: .studentFees) == [.student(hemanth), .studentFees(hemanth)])
        #expect(Fixtures.initialState(for: .studentFees) == .ready(Fixtures.meeraWorkspace))
    }

    @MainActor @Test func thePaymentsStatesOpenFromSettings() {
        for state in [LaunchState.paymentsEmpty, .payments, .paymentsQR] {
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.settings, .payments])
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.workspace(for: state)))
        }
        #expect(Fixtures.workspace(for: .paymentsEmpty).centre.payments.upiID == nil)
        #expect(Fixtures.workspace(for: .payments).centre.payments.upiID == "meera@okhdfcbank")
        let centre = Fixtures.meeraWorkspace.centre.id
        #expect(Fixtures.dependencies(for: .paymentsQR).qrImages.image(for: centre) != nil)
        #expect(Fixtures.dependencies(for: .payments).qrImages.image(for: centre) == nil)
    }

    @MainActor @Test func theReportsStatesOpenFromMore() {
        for state in [LaunchState.reports, .reportsAttendance, .reportsExport, .reportsEmpty] {
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.reports])
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace))
        }
        #expect(RootView.reportsBoardState(.reportsExport) == .export)
        #expect(RootView.reportsBoardState(.reportsEmpty) == .november && RootView.reportsBoardState(.reports) == nil)
    }

    @MainActor @Test func theAIStatesStartOnTheMoreTabAtTheirRoute() {
        for state in RootView.aiStates {
            #expect(Fixtures.initialState(for: state) == .ready(Fixtures.meeraWorkspace), "\(state)")
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state).first == .aiAssistant)
        }
        #expect(RootView.initialRoutes(for: .aiPaper) == [.aiAssistant, .aiForm(.paper)])
        #expect(RootView.initialRoutes(for: .aiResultPaper) == [
            .aiAssistant,
            .aiResult(FakeAIHistoryRepository.quadraticID),
        ])
        #expect(RootView.initialRoutes(for: .aiHistoryEmpty) == [.aiAssistant, .aiHistory])
        #expect(RootView.aiBoardState(.aiGenerating) == .generating && RootView.aiBoardState(.aiNoteSend) == .noteSend)
        #expect(RootView.tab(for: .todayAI) == .today && RootView.todayBoardState(.todayAI) == .aiRow)
        #expect(Fixtures.aiForms(for: .aiPaper)[.paper]?.isValid == true)
    }

    @MainActor @Test func theScanAndCheckStatesStartOnTheirStacks() {
        for state in RootView.scanStates {
            #expect(RootView.tab(for: state) == .more && RootView.initialRoutes(for: state) == [.scanRegister])
            #expect(Fixtures.workspace(for: state).centre.aiConsentAt != nil || state == .scanConsent)
        }
        #expect(RootView.tab(for: .scanSaved) == .students)
        let visit = RootView.checkVisit
        #expect(RootView.initialRoutes(for: .checkIntro) == [.checkPaper(visit)])
        #expect(RootView.initialRoutes(for: .checkSaved).last == .checkResult(visit))
        #expect(RootView.checkBoardState(.checkMarkPicker) == .markPicker && RootView.tab(for: .checkFailed) == .more)
    }
}
