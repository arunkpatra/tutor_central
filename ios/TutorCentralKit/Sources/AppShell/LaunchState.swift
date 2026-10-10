import Foundation

/// A state the screenshot tool can launch the app into (`tools/shots.ts`): `--state <name>`. Every state a board
/// draws gets a case (information-architecture.md, "Launch states"); the Kit's cases open the Kit at each of its
/// sections, since a screenshot holds one screen.
public enum LaunchState: String, CaseIterable, Sendable {
    case placeholder
    case kit
    case kitFields = "kit-fields"
    case kitSurfaces = "kit-surfaces"
    case kitPatterns = "kit-patterns"
    case kitDialog = "kit-dialog"
    case kitPhase7 = "kit-phase7"
    case signin
    case signinEmail = "signin-email"
    case signinCode = "signin-code"
    case signinCodeWrong = "signin-code-wrong"
    case signinPassword = "signin-password"
    case onboarding
    case todayEmpty = "today-empty"
    case laterStudents = "later-students"
    case laterAttendance = "later-attendance"
    /// The School tab's Later card (P2-Later's pattern, P10-School-Empty's symbol) until Phase 13.
    case laterSchool = "later-school"
    case laterMore = "later-more"
    case settings
    case studentsEmpty = "students-empty"
    case studentsFew = "students-few"
    case students
    case studentsSearching = "students-searching"
    case studentsFiltered = "students-filtered"
    case studentsAddMenu = "students-add-menu"
    case studentNew = "student-new"
    case studentNewFilled = "student-new-filled"
    case studentNewInvalid = "student-new-invalid"
    case studentNewNewClass = "student-new-new-class"
    case studentNewClassMade = "student-new-class-made"
    /// V2's New student (P10-NewStudent-Class9, -ClassPicker, -School, -End).
    case studentNewClass9 = "student-new-class9"
    case studentNewClassPicker = "student-new-class-picker"
    case studentNewSchool = "student-new-school"
    case studentNewEnd = "student-new-end"
    /// V2's student page (P10-Student-Record, -End, -NotKnown, -Ladder).
    case studentRecord = "student-record"
    case studentEnd = "student-end"
    case studentNotKnown = "student-not-known"
    case studentLadder = "student-ladder"
    /// Consent (P10-Consent-Ask, -Record, P10-Student-Consent-Waiting), over Riya's page.
    case studentConsentAsk = "student-consent-ask"
    case studentConsentRecord = "student-consent-record"
    case studentConsentWaiting = "student-consent-waiting"
    /// Add a textbook for Riya's Mathematics (P10-Textbook-Intro, -Reading, -Chapters, -Chapter-Edit).
    case textbookIntro = "textbook-intro"
    case textbookReading = "textbook-reading"
    case textbookChapters = "textbook-chapters"
    case textbookChapterEdit = "textbook-chapter-edit"
    /// The placement for Riya (P10-Placement), the first three answers tapped.
    case placement
    case student
    case studentArchived = "student-archived"
    case studentArchiveConfirm = "student-archive-confirm"
    case studentDeleteConfirm = "student-delete-confirm"
    case studentEdit = "student-edit"
    case classesEmpty = "classes-empty"
    case classes
    case classNew = "class-new"
    case classEdit = "class-edit"
    case classArchiveConfirm = "class-archive-confirm"
    case classDetail = "class"
    case classAddMembers = "class-add-members"
    case attendance
    case attendanceClassMenu = "attendance-class-menu"
    case attendanceExceptions = "attendance-exceptions"
    case attendanceSaveFailed = "attendance-save-failed"
    case attendanceSaved = "attendance-saved"
    case attendanceAlert = "attendance-alert"
    case attendancePast = "attendance-past"
    case attendanceEmpty = "attendance-empty"
    case history
    case historyByStudent = "history-by-student"
    case historyStudent = "history-student"
    case historyEmpty = "history-empty"
    case schedule
    case scheduleDay = "schedule-day"
    case eventNew = "event-new"
    case eventEdit = "event-edit"
    case eventEditKeyboard = "event-edit-keyboard"
    case eventGone = "event-gone"
    case eventDeleteConfirm = "event-delete-confirm"
    case tasks
    case tasksEmpty = "tasks-empty"
    /// Today with the Evening batch's plan (P10-Today-Plan, dark and light).
    case today
    /// Scrolled to the smaller groups, the brief and V1's sections (P10-Today-Plan-Scrolled).
    case todayScrolled = "today-scrolled"
    /// The plan being made (P10-Today-Planning).
    case todayPlanning = "today-planning"
    /// Dev's line pressed (P10-Today-Plan-StudentMenu).
    case todayLineMenu = "today-line-menu"
    /// Riya moved to Group 1, Nikhil's homework skipped (P10-Today-Plan-Changed).
    case todayPlanChanged = "today-plan-changed"
    /// The Change sheet (P10-Today-Plan-Change).
    case todayPlanChange = "today-plan-change"
    /// Saturday 10 October: no batch, the next on Monday (P10-Today-NoBatch).
    case todayNoBatch = "today-no-batch"
    case todayAddingTask = "today-adding-task"
    /// The hero after the close over the plan's cards (P10-Today-AfterClose, without To parents): the Evening batch
    /// closed at 18:32.
    case todayAfterClose = "today-after-close"
    /// The close of the Evening batch (P10-Close, -Scrolled, -Placement).
    case close
    case closeScrolled = "close-scrolled"
    case closePlacement = "close-placement"
    case more
    case feesEmpty = "fees-empty"
    case fees
    case feesLoadFailed = "fees-load-failed"
    case feesDue = "fees-due"
    case feesPaid = "fees-paid"
    case feesOverdue = "fees-overdue"
    case feesPayee = "fees-payee"
    case feesGenerate = "fees-generate"
    case feesGenerateNothing = "fees-generate-nothing"
    case feesMarkPaid = "fees-mark-paid"
    case feesMarkedPaid = "fees-marked-paid"
    case feesReceipt = "fees-receipt"
    case feesRemind = "fees-remind"
    case feesWaive = "fees-waive"
    case studentFeesDue = "student-fees-due"
    case studentFees = "student-fees"
    case paymentsEmpty = "payments-empty"
    case payments
    case paymentsQR = "payments-qr"
    case reports
    case reportsAttendance = "reports-attendance"
    case reportsExport = "reports-export"
    case reportsEmpty = "reports-empty"
    case aiAssistant = "ai-assistant"
    case aiAssistantEmpty = "ai-assistant-empty"
    case aiPaper = "ai-paper"
    case aiHomework = "ai-homework"
    case aiWorksheet = "ai-worksheet"
    case aiNote = "ai-note"
    case aiNoteStudent = "ai-note-student"
    case aiGenerating = "ai-generating"
    case aiGenerateFailed = "ai-generate-failed"
    case aiResultPaper = "ai-result-paper"
    case aiResultCopied = "ai-result-copied"
    case aiResultRegenerating = "ai-result-regenerating"
    case aiResultNote = "ai-result-note"
    case aiNoteSend = "ai-note-send"
    case aiHistory = "ai-history"
    case aiHistoryEmpty = "ai-history-empty"
    case todayAI = "today-ai"
    case scanIntro = "scan-intro"
    case scanConsent = "scan-consent"
    case scanCameraRefused = "scan-camera-refused"
    case scanReading = "scan-reading"
    case scanReview = "scan-review"
    case scanReviewScrolled = "scan-review-scrolled"
    case scanReviewEdit = "scan-review-edit"
    case scanReviewRemoved = "scan-review-removed"
    case scanReviewLeave = "scan-review-leave"
    case scanNothing = "scan-nothing"
    case scanFailed = "scan-failed"
    case scanSaved = "scan-saved"
    case checkIntro = "check-intro"
    case checkPages = "check-pages"
    case checkScheme = "check-scheme"
    case checkSchemeTyped = "check-scheme-typed"
    case checkChecking = "check-checking"
    case checkResult = "check-result"
    case checkMarkPicker = "check-mark-picker"
    case checkResultEdited = "check-result-edited"
    case checkResultScrolled = "check-result-scrolled"
    case checkSaved = "check-saved"
    case checkFailed = "check-failed"
    case settingsEnd = "settings-end"
    case settingsSaveFailed = "settings-save-failed"
    case help
    case helpAnswer = "help-answer"
    case account
    case accountPassword = "account-password"
    case accountPasswordFailed = "account-password-failed"
    case accountPasswordSaved = "account-password-saved"
    case accountSignOut = "account-sign-out"
    case accountSignOutPending = "account-sign-out-pending"
    case deleteAccount = "delete-account"
    case deleteAccountTyped = "delete-account-typed"
    case deleteAccountDeleting = "delete-account-deleting"
    case deleteAccountFailed = "delete-account-failed"
    case signinDeleted = "signin-deleted"
    case offlineToday = "offline-today"
    case offlineStudents = "offline-students"
    case offlineFees = "offline-fees"
    case offlineNoCache = "offline-no-cache"
    case offlineWriteRefused = "offline-write-refused"
    case offlineAttendanceSaved = "offline-attendance-saved"
    case offlineFeeMarked = "offline-fee-marked"
    case syncSending = "sync-sending"
    case syncSent = "sync-sent"
    case syncFailed = "sync-failed"
    case pending
    case pendingDiscard = "pending-discard"
    case remindersNotAsked = "reminders-not-asked"
    case reminders
    case remindersAllOff = "reminders-all-off"
    case remindersRefused = "reminders-refused"
    case remindersDayPicker = "reminders-day-picker"

    public static func fromArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchState? {
        guard let i = arguments.firstIndex(of: "--state"), arguments.indices.contains(i + 1) else { return nil }
        return LaunchState(rawValue: arguments[i + 1])
    }
}
