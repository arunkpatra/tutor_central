import Attendance
import Data
import DesignSystem
import Domain
import Fees
import Onboarding
import Schedule
import Students
import SwiftUI
import Today

/// How each launch state sets the root up: its tab, what its stack opens, and the board state a screen is told.
extension RootView {
    static func tab(for state: LaunchState) -> AppTab? {
        switch state {
        case .laterStudents, .studentsEmpty, .studentsFew, .students, .studentsSearching, .studentsFiltered,
             .studentsAddMenu, .studentNew, .studentNewFilled, .studentNewInvalid, .student, .studentArchived,
             .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit, .classesEmpty, .classes, .classNew,
             .classEdit,
             .classArchiveConfirm, .classDetail, .classAddMembers: .students
        case .feesEmpty, .fees, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate, .feesGenerateNothing,
             .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind, .feesWaive: .fees
        case .laterAttendance, .attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaved,
             .attendanceAlert, .attendancePast, .attendanceEmpty, .history, .historyByStudent, .historyStudent,
             .historyEmpty: .attendance
        case .laterMore, .more, .schedule, .scheduleDay, .eventNew, .eventEdit, .eventDeleteConfirm, .tasks,
             .tasksEmpty:
            .more
        default: nil
        }
    }

    /// What a launch state opens on its tab's stack: Settings, or Akshita's detail.
    static func initialRoutes(for state: LaunchState) -> [Route] {
        switch state {
        case .settings: [.settings]
        case .student, .studentArchived, .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit:
            [.student(FakeStudentsRepository.akshita)]
        case .classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm: [.classes]
        case .classDetail, .classAddMembers: [.classroom(FakeClassesRepository.maths.id)]
        case .history, .historyByStudent, .historyEmpty: [.history]
        case .historyStudent: [.history, .historyStudent(FakeAttendanceRepository.hemanth)]
        case .schedule, .scheduleDay, .eventNew, .eventEdit, .eventDeleteConfirm: [.schedule]
        case .tasks, .tasksEmpty: [.tasks]
        default: []
        }
    }

    static func signInFixture(_ state: LaunchState) -> SignInFixture? {
        switch state {
        case .signinEmail: .email
        case .signinCode: .code
        case .signinCodeWrong: .codeWrong
        case .signinPassword: .password
        default: nil
        }
    }

    static func studentDetailBoardState(_ state: LaunchState) -> StudentDetailBoardState? {
        switch state {
        case .studentArchiveConfirm: .archiveConfirm
        case .studentDeleteConfirm: .deleteConfirm
        case .studentEdit: .edit
        default: nil
        }
    }

    static func studentsBoardState(_ state: LaunchState) -> StudentsBoardState? {
        switch state {
        case .studentsSearching: .searching
        case .studentsFiltered: .filteredToScience
        case .studentsAddMenu: .addMenu
        case .studentNew: .newStudentEmpty
        case .studentNewFilled: .newStudentFilled
        case .studentNewInvalid: .newStudentInvalid
        default: nil
        }
    }

    static func classesBoardState(_ state: LaunchState) -> ClassesBoardState? {
        switch state {
        case .classNew: .newClass
        case .classEdit: .editMaths
        case .classArchiveConfirm: .archiveMaths
        default: nil
        }
    }

    static func attendanceBoardState(_ state: LaunchState) -> AttendanceBoardState? {
        switch state {
        case .attendanceClassMenu: .classMenu
        case .attendanceExceptions: .oneAbsent
        case .attendanceSaved: .saved
        case .attendanceAlert: .alert
        case .attendancePast: .past
        default: nil
        }
    }

    static func historyBoardState(_ state: LaunchState) -> HistoryBoardState? {
        state == .historyByStudent ? .byStudent : nil
    }

    static func scheduleBoardState(_ state: LaunchState) -> ScheduleBoardState? {
        switch state {
        case .scheduleDay: .saturday
        case .eventNew: .newEvent
        case .eventEdit: .editEvent
        case .eventDeleteConfirm: .deleteConfirm
        default: nil
        }
    }

    static func feesBoardState(_ state: LaunchState) -> FeesBoardState? {
        switch state {
        case .feesDue: .due
        case .feesPaid: .paid
        case .feesOverdue: .september
        case .feesGenerate, .feesGenerateNothing: .generate
        case .feesMarkPaid: .markPaid
        case .feesMarkedPaid: .markedPaid
        case .feesReceipt: .receipt
        case .feesRemind: .remind
        case .feesWaive: .waive
        default: nil
        }
    }

    static func todayBoardState(_ state: LaunchState) -> TodayBoardState? {
        state == .todayAddingTask ? .addingTask : nil
    }

    static func classDetailBoardState(_ state: LaunchState) -> ClassDetailBoardState? {
        state == .classAddMembers ? .addMembers : nil
    }

    /// The toast's Retry for the register's last failed write.
    static func retry(_ store: RegisterStore) -> (label: String, run: @MainActor () -> Void) {
        let run: @MainActor () -> Void = {
            Task { await store.retryLast() }
        }
        return ("Retry", run)
    }

    /// The toast's Retry for the mark screen's failed save.
    static func retry(_ store: AttendanceStore) -> (label: String, run: @MainActor () -> Void) {
        let run: @MainActor () -> Void = {
            Task { await store.retryLast() }
        }
        return ("Retry", run)
    }

    /// The toast's Retry for a fee's failed write.
    static func retry(_ store: FeesStore) -> (label: String, run: @MainActor () -> Void) {
        let run: @MainActor () -> Void = {
            Task { await store.retryLast() }
        }
        return ("Retry", run)
    }

    /// The toast's Retry for a task's failed write.
    static func retry(_ store: TasksStore) -> (label: String, run: @MainActor () -> Void) {
        let run: @MainActor () -> Void = {
            Task { await store.retryLast() }
        }
        return ("Retry", run)
    }

    #if DEBUG
        static func kitSection(_ state: LaunchState?) -> KitView.Section? {
            switch state {
            case .kit: .controls
            case .kitFields: .fields
            case .kitSurfaces: .surfaces
            case .kitPatterns: .patterns
            case .kitDialog: .dialog
            default: nil
            }
        }
    #endif
}
