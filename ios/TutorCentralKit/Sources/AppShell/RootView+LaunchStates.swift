import AITools
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
             .classArchiveConfirm, .classDetail, .classAddMembers, .studentFeesDue, .studentFees: .students
        case .feesEmpty, .fees, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate, .feesGenerateNothing,
             .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind, .feesWaive: .fees
        case .laterAttendance, .attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaved,
             .attendanceAlert, .attendancePast, .attendanceEmpty, .history, .historyByStudent, .historyStudent,
             .historyEmpty: .attendance
        case .paymentsEmpty, .payments, .paymentsQR, .reports, .reportsAttendance, .reportsExport, .reportsEmpty: .more
        case .laterMore, .more, .schedule, .scheduleDay, .eventNew, .eventEdit, .eventDeleteConfirm, .tasks,
             .tasksEmpty:
            .more
        case .todayAI: .today
        case .scanSaved: .students
        default: aiStates.contains(state) || scanStates.contains(state) || checkStates.contains(state) ? .more : nil
        }
    }

    /// The AI Assistant's states, all on the More tab's stack.
    static let aiStates: Set<LaunchState> = [
        .aiAssistant, .aiAssistantEmpty, .aiPaper, .aiHomework, .aiWorksheet, .aiNote, .aiNoteStudent, .aiGenerating,
        .aiGenerateFailed, .aiResultPaper, .aiResultRegenerating, .aiResultNote, .aiNoteSend, .aiHistory,
        .aiHistoryEmpty,
    ]

    /// Scan register's states, on the More tab's stack (Saved is the Students list).
    static let scanStates: Set<LaunchState> = [
        .scanIntro, .scanConsent, .scanCameraRefused, .scanReading, .scanReview, .scanReviewEdit, .scanReviewRemoved,
        .scanReviewLeave, .scanNothing, .scanFailed,
    ]

    /// Check a paper's states, on the More tab's stack; one visit id for all of them.
    static let checkStates: Set<LaunchState> = [
        .checkIntro, .checkPages, .checkScheme, .checkSchemeTyped, .checkChecking, .checkResult, .checkMarkPicker,
        .checkResultEdited, .checkSaved, .checkFailed,
    ]
    static let checkVisit = UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001") ?? UUID()

    static func checkRoutes(for state: LaunchState) -> [Route] {
        let id = checkVisit
        return switch state {
        case .checkIntro: [.checkPaper(id)]
        case .checkPages: [.checkPaper(id), .checkPages(id)]
        case .checkScheme, .checkSchemeTyped: [.checkPaper(id), .checkPages(id), .checkScheme(id)]
        case .checkChecking, .checkResult, .checkMarkPicker, .checkResultEdited, .checkSaved, .checkFailed:
            [.checkPaper(id), .checkPages(id), .checkScheme(id), .checkResult(id)]
        default: []
        }
    }

    static func checkBoardState(_ state: LaunchState) -> CheckBoardState? {
        switch state {
        case .checkSchemeTyped: .typed
        case .checkMarkPicker: .markPicker
        case .checkResultEdited: .edited
        case .checkSaved: .saved
        default: nil
        }
    }

    static func scanBoardState(_ state: LaunchState) -> ScanBoardState? {
        switch state {
        case .scanConsent: .consent
        case .scanCameraRefused: .cameraRefused
        case .scanReading: .reading
        case .scanReview: .review
        case .scanReviewEdit: .edit
        case .scanReviewRemoved: .rowRemoved
        case .scanReviewLeave: .leave
        case .scanNothing: .nothing
        case .scanFailed: .failed
        default: nil
        }
    }

    /// The AI Assistant's stack for each of its states.
    static func aiRoutes(for state: LaunchState) -> [Route] {
        let note = FakeAIHistoryRepository.id(2)
        return switch state {
        case .aiAssistant, .aiAssistantEmpty: [.aiAssistant]
        case .aiPaper, .aiGenerating, .aiGenerateFailed: [.aiAssistant, .aiForm(.paper)]
        case .aiHomework: [.aiAssistant, .aiForm(.homework)]
        case .aiWorksheet: [.aiAssistant, .aiForm(.worksheet)]
        case .aiNote, .aiNoteStudent: [.aiAssistant, .aiForm(.progressNote)]
        case .aiResultPaper, .aiResultRegenerating: [.aiAssistant, .aiResult(FakeAIHistoryRepository.quadraticID)]
        case .aiResultNote, .aiNoteSend: [.aiAssistant, .aiResult(note)]
        case .aiHistory, .aiHistoryEmpty: [.aiAssistant, .aiHistory]
        default: scanStates.contains(state) ? [.scanRegister] : checkRoutes(for: state)
        }
    }

    static func aiBoardState(_ state: LaunchState) -> AIBoardState? {
        switch state {
        case .aiNoteStudent: .studentPicker
        case .aiGenerating: .generating
        case .aiGenerateFailed: .failed
        case .aiResultRegenerating: .regenerating
        case .aiNoteSend: .noteSend
        default: nil
        }
    }

    /// The forms the boards draw with the focus ring on the field being typed in.
    static func showsFocus(_ state: LaunchState) -> Bool {
        [.aiPaper, .aiHomework, .aiWorksheet, .aiNote].contains(state)
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
        default: studentFeesRoutes(for: state)
        }
    }

    /// Hemanth's detail (P5-StudentDetail-Fees), and his fees over it (P5-StudentFees).
    private static func studentFeesRoutes(for state: LaunchState) -> [Route] {
        switch state {
        case .studentFeesDue: [.student(FakeAttendanceRepository.hemanth)]
        case .studentFees: [.student(FakeAttendanceRepository.hemanth), .studentFees(FakeAttendanceRepository.hemanth)]
        case .paymentsEmpty, .payments, .paymentsQR: [.settings, .payments]
        case .reports, .reportsAttendance, .reportsExport, .reportsEmpty: [.reports]
        default: aiRoutes(for: state)
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

    static func paymentsBoardState(_ state: LaunchState) -> PaymentsBoardState? {
        switch state {
        case .paymentsEmpty: .empty
        case .payments: .saved
        case .paymentsQR: .fromQR
        default: nil
        }
    }

    static func reportsBoardState(_ state: LaunchState) -> ReportsBoardState? {
        switch state {
        case .reportsAttendance: .attendance
        case .reportsExport: .export
        case .reportsEmpty: .november
        default: nil
        }
    }

    static func todayBoardState(_ state: LaunchState) -> TodayBoardState? {
        switch state {
        case .todayAddingTask: .addingTask
        case .todayAI: .aiRow
        default: nil
        }
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
