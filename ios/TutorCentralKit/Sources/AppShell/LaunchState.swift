import Foundation

/// A state the screenshot tool can launch the app into (`tools/shots.ts`): `--state <name>`. Every state a board
/// draws gets a case (information-architecture.md, "Launch states"); the Kit's cases open the Kit at each of its
/// sections, since a screenshot holds one screen.
public enum LaunchState: String, CaseIterable, Sendable {
    case placeholder, kit
    case kitFields = "kit-fields", kitSurfaces = "kit-surfaces", kitPatterns = "kit-patterns", kitDialog = "kit-dialog"
    case kitPhase7 = "kit-phase7", kitPhase10 = "kit-phase10", kitPhase10Figures = "kit-phase10-figures"
    case signin, signinEmail = "signin-email", signinCode = "signin-code", signinCodeWrong = "signin-code-wrong"
    case signinPassword = "signin-password"
    case onboarding
    case todayEmpty = "today-empty"
    case laterStudents = "later-students"
    case laterAttendance = "later-attendance"
    case laterMore = "later-more"
    /// The School tab (Phase 13): P10-School-Empty, -List, -Calendar, -AddMenu, P13-School-Reading, P10-School-Confirm,
    /// -Confirm-Edit, and an item's page as a homework's and a holiday's.
    case schoolEmpty = "school-empty"
    case school
    case schoolCalendar = "school-calendar"
    case schoolAddMenu = "school-add-menu"
    case schoolReading = "school-reading"
    case schoolConfirm = "school-confirm"
    case schoolConfirmEdit = "school-confirm-edit"
    /// The exam's page nine days out with Who and Preparation (P10-School-Item), its edit sheet and delete dialog.
    case schoolItem = "school-item"
    case schoolItemEdit = "school-item-edit"
    case schoolItemDelete = "school-item-delete"
    case schoolItemHomework = "school-item-homework"
    /// The exam's page on the mock day, leading with the last days (P10-School-Exam-LastDays), and Dev's gap report
    /// (P10-GapReport).
    case schoolLastDays = "school-last-days"
    case gapReport = "gap-report"
    case schoolItemHoliday = "school-item-holiday"
    /// Ask parents to forward with two sent (P10-School-Ask).
    case schoolAsk = "school-ask"
    /// Today's plan made with Group 1 as the exam group and its revision lines (P13-Today-Revision).
    case todayRevision = "today-revision"
    /// The mock for Dev's own test in the school's pattern, and its key (P10-Mock).
    case mock
    case mockKey = "mock-key"
    /// Ask parents to forward when who was asked could not be read (feedback.md, a list that could not load).
    case schoolAskFailed = "school-ask-failed"
    /// Test tomorrow in Hindi with the English beside, over Dev's exam (P10-TestTomorrow).
    case schoolTestTomorrow = "school-test-tomorrow"
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
    /// Hemanth's Checks and Marks (P13-Student-Marks), and Riya's page with no marks yet (P13-Student-Marks-Empty).
    case studentMarks = "student-marks"
    case studentMarksEmpty = "student-marks-empty"
    case studentEnd = "student-end"
    case studentNotKnown = "student-not-known"
    case studentLadder = "student-ladder"
    /// Consent (P10-Consent-Ask, -Record, P10-Student-Consent-Waiting), over Riya's page.
    case studentConsentAsk = "student-consent-ask", studentConsentRecord = "student-consent-record"
    case studentConsentWaiting = "student-consent-waiting"
    /// Phase 18 over Hemanth's page: the record sheet with Parent withdrew (P18-Consent-Change), the withdraw sheet
    /// (P18-Consent-Withdraw), the page withdrawn with its history (P18-Student-Withdrawn).
    case studentConsentChange = "student-consent-change", studentConsentWithdraw = "student-consent-withdraw"
    case studentWithdrawn = "student-withdrawn"
    /// The Export section at the foot of Hemanth's page: the ask, being made, ready, not made (P18-Export-*).
    case studentExport = "student-export", studentExportMaking = "student-export-making"
    case studentExportReady = "student-export-ready", studentExportFailed = "student-export-failed"
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
    /// Today at 06:05: the plan the server made at 06:00, its material still being made (P18-Today-Plan-Making).
    case todayPlanMaking = "today-plan-making"
    /// The plan job failed: Phase 12's failed card with Try Again, in Phase 18's words.
    case todayPlanFailed = "today-plan-failed"
    /// Dev's line pressed (P10-Today-Plan-StudentMenu).
    case todayLineMenu = "today-line-menu"
    /// Riya moved to Group 1, Nikhil's homework skipped (P10-Today-Plan-Changed).
    case todayPlanChanged = "today-plan-changed"
    /// The Change sheet (P10-Today-Plan-Change).
    case todayPlanChange = "today-plan-change"
    /// Saturday 10 October: no batch, the next on Monday (P10-Today-NoBatch).
    case todayNoBatch = "today-no-batch"
    /// Today at 19:30 (V1's store page, Store-1-Today, until Phase 16 redoes the store boards).
    case todayEvening = "today-evening"
    case todayAddingTask = "today-adding-task"
    /// The hero after the close over the plan's cards (P10-Today-AfterClose, without To parents): the Evening batch
    /// closed at 18:32.
    case todayAfterClose = "today-after-close"
    /// Phase 14. Sunday 11 October 18:30: the note day's hero and Notes (P10-Today-NoteDay); Dev's note held with the
    /// held sheet up (P10-Held); the note day's wheel (P10-NoteDay-Change).
    case todayNoteDay = "today-note-day"
    case todayNoteHeld = "today-note-held"
    case todayNoteDayChange = "today-note-day-change"
    /// Dev's weekly note in Hindi (P10-Note, -Light); the two-language sheet (P10-Note-Send); Sahil's can-now-do
    /// (P10-CanNowDo); the note being written.
    case note
    case noteSend = "note-send"
    /// `noteCanDoNoChange`: Sahil's can-now-do in a week no step moved (P14-CanNowDo-NoChange, U46).
    case noteCanDo = "note-can-do", noteCanDoNoChange = "note-can-do-no-change"
    case noteWriting = "note-writing"
    /// Dev's sent log with Held (P10-Student-Messages).
    case studentMessages = "student-messages"
    /// Friday 9 October: Dev not on track (P10-Student-NotOnTrack), the next step (P10-NextStep), the message to the
    /// parent (P10-NotOnTrack-Message), Today's caption (P10-Today-NotOnTrack).
    case studentNotOnTrack = "student-not-on-track"
    case studentNextStep = "student-next-step"
    case studentTellParent = "student-tell-parent"
    case todayNotOnTrack = "today-not-on-track"
    /// Marks from a photo (P14-Marks-Reading, -Confirm, -Edit).
    case marksReading = "marks-reading"
    case marksConfirm = "marks-confirm"
    case marksEdit = "marks-edit"
    /// U41 to U43 (P14-School-Paste, -Student, -Item-Window).
    case schoolPaste = "school-paste"
    case schoolStudent = "school-student"
    case schoolItemWindow = "school-item-window"
    /// Group 1's homework sheet (P10-Sheet, dark and light); its key; the board at question 3.
    case sheet
    case sheetKey = "sheet-key"
    case sheetBoard = "sheet-board"
    /// Make it again: the reasons; being made easier (P10-Sheet-Regenerate, -Regenerating).
    case sheetRegenerate = "sheet-regenerate"
    case sheetRegenerating = "sheet-regenerating"
    /// Use my own: the three ways; the tutor's photo in the sheet's place (P10-Sheet-OwnMenu, -Own).
    case sheetOwnMenu = "sheet-own-menu"
    case sheetOwn = "sheet-own"
    /// Group 1's worked example at its second step (P10-WorkedExample); the Chemical reactions brief (P10-Brief).
    case workedExample = "worked-example"
    case brief
    /// The seven figures (P10-Figure-*), each on its board's skill.
    case figureNumberLine = "figure-number-line"
    case figureFractionBar = "figure-fraction-bar"
    case figurePlaceValue = "figure-place-value"
    case figureUnitCircle = "figure-unit-circle"
    case figureTriangle = "figure-triangle"
    case figureCell = "figure-cell"
    case figureFoodChain = "figure-food-chain"
    /// The close of the Evening batch (P10-Close, -Scrolled, -Placement).
    case close
    case closeScrolled = "close-scrolled"
    case closePlacement = "close-placement"
    /// The close card's three states (P12-Close-Cards): Dev's checks being made, Bir with no book, Riya offline.
    case closeCards = "close-cards"
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
    case reports, reportsAttendance = "reports-attendance", reportsExport = "reports-export"
    case reportsEmpty = "reports-empty", reportsProgress = "reports-progress"
    case reportsProgressTerm = "reports-progress-term", reportsProgressSort = "reports-progress-sort"
    case reportsProgressExport = "reports-progress-export", reportsProgressEmpty = "reports-progress-empty"
    case make, makeEmpty = "make-empty", makeSheet = "make-sheet", makeFor = "make-for"
    case makeForStudent = "make-for-student", makeWorkedExample = "make-worked-example", makeFigure = "make-figure"
    case aiPaper = "ai-paper", makeSheetNoClass = "make-sheet-no-class"
    /// The paper's Class tile open on the class wheel; the paper with nothing chosen yet (P12-Form-Paper-ClassWheel,
    /// -NoClass).
    case aiPaperClassWheel = "ai-paper-class-wheel"
    case aiPaperNoClass = "ai-paper-no-class"
    case aiHomework = "ai-homework"
    case aiWorksheet = "ai-worksheet"
    case aiNote = "ai-note", aiNoteStudent = "ai-note-student", aiNoteConsent = "ai-note-consent"
    case aiGenerating = "ai-generating"
    case aiGenerateFailed = "ai-generate-failed", aiHomeworkFailed = "ai-homework-failed"
    case aiResultPaper = "ai-result-paper"
    case aiResultCopied = "ai-result-copied"
    case aiResultRegenerating = "ai-result-regenerating"
    case aiResultNote = "ai-result-note"
    case aiNoteSend = "ai-note-send"
    case aiHistory = "ai-history", aiHistoryEmpty = "ai-history-empty", makeMade = "make-made"
    case makeBrief = "make-brief", makeMock = "make-mock", makeNote = "make-note", makeMaking = "make-making"
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
    case checkIntro = "check-intro", checkSchemeChooser = "check-scheme-chooser", checkPagesEmpty = "check-pages-empty"
    case checkConsentWaiting = "check-consent-waiting", checkIntroMock = "check-intro-mock"
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
