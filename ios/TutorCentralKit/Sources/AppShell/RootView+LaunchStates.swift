import AITools
import Attendance
import Data
import DesignSystem
import Domain
import Fees
import Onboarding
import Schedule
import Settings
import Students
import SwiftUI
import Today

/// How each launch state sets the root up: its tab, what its stack opens, and the board state a screen is told.
extension RootView {
    static func tab(for state: LaunchState) -> AppTab? {
        switch state {
        case .laterStudents, .studentsEmpty, .studentsFew, .students, .studentsSearching, .studentsFiltered,
             .studentsAddMenu, .studentNew, .studentNewFilled, .studentNewInvalid, .studentNewNewClass,
             .studentNewClassMade, .studentNewClass9, .studentNewClassPicker, .studentNewSchool, .studentNewEnd,
             .student, .studentRecord, .studentEnd, .studentNotKnown, .studentLadder, .studentConsentAsk,
             .studentConsentRecord, .studentConsentWaiting, .textbookIntro, .textbookReading, .textbookChapters,
             .textbookChapterEdit, .placement, .studentArchived,
             .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit, .classesEmpty, .classes, .classNew,
             .classEdit,
             .classArchiveConfirm, .classDetail, .classAddMembers, .studentFeesDue, .studentFees: .students
        case .feesEmpty, .fees, .feesLoadFailed, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate,
             .feesGenerateNothing,
             .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind, .feesWaive: .fees
        case .laterAttendance, .attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaveFailed,
             .attendanceSaved,
             .attendanceAlert, .attendancePast, .attendanceEmpty, .history, .historyByStudent, .historyStudent,
             .historyEmpty: .more
        case .laterSchool: .school
        case .paymentsEmpty, .payments, .paymentsQR, .reports, .reportsAttendance, .reportsExport, .reportsEmpty: .more
        case .laterMore, .more, .schedule, .scheduleDay, .eventNew, .eventEdit, .eventEditKeyboard, .eventGone,
             .eventDeleteConfirm,
             .tasks,
             .tasksEmpty:
            .more
        case .todayAI: .today
        case .scanSaved: .students
        default: Fixtures.offlineTab(state)
            ?? (aiStates.contains(state) || scanStates.contains(state) || checkStates.contains(state) ? .more : nil)
        }
    }

    /// The AI Assistant's states, all on the More tab's stack.
    static let aiStates: Set<LaunchState> = [
        .aiAssistant, .aiAssistantEmpty, .aiPaper, .aiHomework, .aiWorksheet, .aiNote, .aiNoteStudent, .aiGenerating,
        .aiGenerateFailed, .aiResultPaper, .aiResultCopied, .aiResultRegenerating, .aiResultNote, .aiNoteSend,
        .aiHistory,
        .aiHistoryEmpty,
    ]

    /// Scan register's states, on the More tab's stack (Saved is the Students list).
    static let scanStates: Set<LaunchState> = [
        .scanIntro, .scanConsent, .scanCameraRefused, .scanReading, .scanReview, .scanReviewScrolled, .scanReviewEdit,
        .scanReviewRemoved, .scanReviewLeave, .scanNothing, .scanFailed,
    ]

    /// Check a paper's states, on the More tab's stack; one visit id for all of them.
    static let checkStates: Set<LaunchState> = [
        .checkIntro, .checkPages, .checkScheme, .checkSchemeTyped, .checkChecking, .checkResult, .checkMarkPicker,
        .checkResultEdited, .checkResultScrolled, .checkSaved, .checkFailed,
    ]
    static let checkVisit = UUID(uuidString: "eeeeeeee-0000-0000-0000-000000000001") ?? UUID()

    static func checkRoutes(for state: LaunchState) -> [Route] {
        let id = checkVisit
        return switch state {
        case .checkIntro: [.checkPaper(id)]
        case .checkPages: [.checkPaper(id), .checkPages(id)]
        case .checkScheme, .checkSchemeTyped: [.checkPaper(id), .checkPages(id), .checkScheme(id)]
        case .checkChecking, .checkResult, .checkMarkPicker, .checkResultEdited, .checkResultScrolled, .checkSaved,
             .checkFailed:
            [.checkPaper(id), .checkPages(id), .checkScheme(id), .checkResult(id)]
        default: []
        }
    }

    static func checkBoardState(_ state: LaunchState) -> CheckBoardState? {
        switch state {
        case .checkSchemeTyped: .typed
        case .checkMarkPicker: .markPicker
        case .checkResultEdited: .edited
        case .checkResultScrolled: .scrolled
        case .checkSaved: .saved
        default: nil
        }
    }

    /// Each Scan register state's board state (a table: the switch passed the lint's complexity).
    static let scanBoardStates: [LaunchState: ScanBoardState] = [
        .scanConsent: .consent, .scanCameraRefused: .cameraRefused, .scanReading: .reading, .scanReview: .review,
        .scanReviewScrolled: .scrolled, .scanReviewEdit: .edit, .scanReviewRemoved: .rowRemoved,
        .scanReviewLeave: .leave, .scanNothing: .nothing, .scanFailed: .failed,
    ]

    static func scanBoardState(_ state: LaunchState) -> ScanBoardState? {
        scanBoardStates[state]
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
        case .aiResultPaper, .aiResultCopied, .aiResultRegenerating:
            [.aiAssistant, .aiResult(FakeAIHistoryRepository.quadraticID)]
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
        case .aiResultCopied: .copied
        default: nil
        }
    }

    /// The forms the boards draw with the focus ring on the field being typed in.
    static func showsFocus(_ state: LaunchState) -> Bool {
        [.aiPaper, .aiHomework, .aiWorksheet, .aiNote].contains(state)
    }

    /// What a launch state opens on its tab's stack: Settings, or Akshita's detail.
    static func initialRoutes(for state: LaunchState) -> [Route] {
        if let routes = settingsRoutes(for: state) ?? attendanceRoutes(for: state) ?? studentPageRoutes(for: state)
            ?? closeRoutes(for: state) ?? artefactRoutes(for: state) {
            return routes
        }
        return switch state {
        case .settings: [.settings]
        case .studentArchived, .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit:
            [.student(FakeStudentsRepository.akshita)]
        case .classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm: [.classes]
        case .classDetail, .classAddMembers: [.classroom(FakeClassesRepository.maths.id)]
        // U33-Event-Gone: a link to an event that was deleted.
        case .schedule, .scheduleDay, .eventNew, .eventEdit, .eventEditKeyboard, .eventDeleteConfirm, .eventGone:
            state == .eventGone ? [.event(Fixtures.goneEvent)] : [.schedule]
        case .tasks, .tasksEmpty: [.tasks]
        default: studentFeesRoutes(for: state)
        }
    }

    /// V2's student page (P10-Student and its scrolls): Hemanth; not known yet: Riya; the ladder: Sahil.
    private static func studentPageRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .student, .studentRecord, .studentEnd: [.student(FakeStudentsRepository.hemanth)]
        case .studentNotKnown, .studentConsentAsk, .studentConsentRecord, .studentConsentWaiting:
            [.student(FakeStudentsRepository.riya)]
        case .studentLadder: [.student(FakeStudentsRepository.sahil)]
        case .placement: [.student(FakeStudentsRepository.riya), .placement(FakeStudentsRepository.riya)]
        case .textbookIntro, .textbookReading, .textbookChapters, .textbookChapterEdit:
            [
                .student(FakeStudentsRepository.riya),
                .textbook(student: FakeStudentsRepository.riya, subject: "Mathematics"),
            ]
        default: nil
        }
    }

    /// Attendance under More (D65): the mark root pushed, History and a student's month over it.
    private static func attendanceRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .attendance, .attendanceClassMenu, .attendanceExceptions, .attendanceSaveFailed, .attendanceSaved,
             .attendanceAlert, .attendancePast, .attendanceEmpty, .offlineAttendanceSaved:
            [.attendance]
        case .history, .historyByStudent, .historyEmpty: [.attendance, .history]
        case .historyStudent: [.attendance, .history, .historyStudent(FakeAttendanceRepository.hemanth)]
        default: nil
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
        case .studentRecord: .record
        case .studentEnd: .end
        case .studentConsentAsk: .consentAsk
        case .studentConsentRecord: .consentRecord
        default: nil
        }
    }

    static func studentsBoardState(_ state: LaunchState) -> StudentsBoardState? {
        studentsBoardStates[state]
    }

    /// Each Students state's board state (a table: the switch passed the lint's complexity).
    static let studentsBoardStates: [LaunchState: StudentsBoardState] = [
        .studentsSearching: .searching, .studentsFiltered: .filteredToScience, .studentsAddMenu: .addMenu,
        .studentNew: .newStudentEmpty, .studentNewFilled: .newStudentFilled, .studentNewInvalid: .newStudentInvalid,
        .studentNewNewClass: .newStudentNewClass, .studentNewClassMade: .newStudentClassMade,
        .studentNewClass9: .newStudentClass9, .studentNewClassPicker: .newStudentClassPicker,
        .studentNewSchool: .newStudentSchool, .studentNewEnd: .newStudentEnd,
    ]

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
        case .attendanceSaveFailed: .saveFailed
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
        case .eventEditKeyboard: .editEventKeyboard
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
        case .todayScrolled: .scrolledToPlan
        case .todayLineMenu: .lineMenu(FakeStudentsRepository.dev)
        case .todayPlanChange: .changeSheet
        case .todayPlanChanged: .planChanged
        default: nil
        }
    }

    static func textbookBoardState(_ state: LaunchState) -> TextbookBoardState? {
        switch state {
        case .textbookReading: .reading
        case .textbookChapters: .chapters
        case .textbookChapterEdit: .chapterEdit
        default: nil
        }
    }

    static func classDetailBoardState(_ state: LaunchState) -> ClassDetailBoardState? {
        state == .classAddMembers ? .addMembers : nil
    }

    /// The alert's Try Again for the register's last failed write (U33).
    static func retry(_ store: RegisterStore) -> @MainActor () -> Void {
        { Task { await store.retryLast() } }
    }

    /// The alert's Try Again for the mark screen's failed save (U33).
    static func retry(_ store: AttendanceStore) -> @MainActor () -> Void {
        { Task { await store.retryLast() } }
    }

    /// The alert's Try Again for a fee's failed write (U33).
    static func retry(_ store: FeesStore) -> @MainActor () -> Void {
        { Task { await store.retryLast() } }
    }

    /// The alert's Try Again for a task's failed write (U33).
    static func retry(_ store: TasksStore) -> @MainActor () -> Void {
        { Task { await store.retryLast() } }
    }

    #if DEBUG
        static func kitSection(_ state: LaunchState?) -> KitView.Section? {
            switch state {
            case .kit: .controls
            case .kitFields: .fields
            case .kitSurfaces: .surfaces
            case .kitPatterns: .patterns
            case .kitDialog: .dialog
            case .kitPhase7: .phase7
            default: nil
            }
        }
    #endif
}

extension RootView {
    /// What the Students boards show over the list: P6-Scan-Saved's Undo after Add; P7-Offline-WriteRefused's alert,
    /// raised
    /// as Save on the sheet does, once the sheet is up (it shows the alert over itself).
    func studentsBoardEffects() {
        if launch == .scanSaved {
            toasts.show(ScanReview.addedToast(count: 7), action: ("Undo", {}), stay: .seconds(3600))
        }
        if launch == .offlineWriteRefused {
            Task {
                try? await Task.sleep(for: .seconds(Tokens.panel * 4))
                notices.show(OfflineRefusal.words(for: .addStudent))
            }
        }
    }
}
