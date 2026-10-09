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
    case eventDeleteConfirm = "event-delete-confirm"
    case tasks
    case tasksEmpty = "tasks-empty"
    case today
    case todayEvening = "today-evening"
    case todayNoClass = "today-no-class"
    case todayAddingTask = "today-adding-task"
    case more
    case feesEmpty = "fees-empty"
    case fees
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
