import Data
import Domain
import Foundation

/// What `bun shots <state>` launches: the fakes, filled with the boards' data, and a fixed clock, so every picture is
/// the same every time and matches its board.
public enum Fixtures {
    /// Wednesday 7 October 2026, 18:30 in India: "Good evening, Meera".
    public static let now = FakeCountsRepository.fixedNow

    public static let meeraWorkspace = FakeCentreRepository.meeraWorkspace
    /// An event id no longer in the schedule (U33-Event-Gone).
    static let goneEvent = UUID(uuidString: "eeeeeeee-0000-0000-0000-00000000dead") ?? UUID()

    @MainActor public static func dependencies(for state: LaunchState) -> Dependencies {
        let (auth, centres) = session(for: state)
        let counts = FakeCountsRepository(counts: counts(for: state))
        let students = FakeStudentsRepository(students: register(for: state).students)
        let fees = FakeFeesRepository(invoices: fees(for: state), now: { clock(for: state) })
        let attendance = FakeAttendanceRepository(sessions: attendance(for: state), now: { clock(for: state) })
        if state == .feesLoadFailed {
            // U33-Fees-LoadFailed: the month does not load, and there is nothing saved to show.
            fees.nextError = URLError(.badServerResponse)
        }
        if state == .attendanceSaveFailed {
            // U33-Attendance-SaveFailed: the save is refused (not a lost connection, which would keep it here).
            attendance.saveError = URLError(.badServerResponse)
        }
        if offlineStates.contains(state) {
            // The boards' offline screens: every read fails for the network; the copies on this iPhone show.
            counts.nextError = URLError(.notConnectedToInternet)
            students.nextError = URLError(.notConnectedToInternet)
            fees.nextError = URLError(.notConnectedToInternet)
            attendance.nextError = URLError(.notConnectedToInternet)
        }
        return Dependencies(
            auth: auth,
            centres: centres,
            counts: counts,
            students: students,
            classes: FakeClassesRepository(classes: register(for: state).classes),
            attendance: attendance,
            messages: messages(for: state),
            schools: FakeSchoolsRepository(schools: boardSchools),
            textbooks: FakeTextbooksRepository.seeded(),
            record: FakeRecordRepository(),
            events: FakeEventsRepository(events: state == .todayEmpty ? [] : FakeEventsRepository.seed),
            tasks: FakeTasksRepository(tasks: [.tasksEmpty, .todayEmpty].contains(state) ? [] : FakeTasksRepository
                .seed),
            fees: fees,
            qrImages: MemoryQRImageStore(images: state == .paymentsQR ? [meeraWorkspace.centre.id: sampleQR()] : [:]),
            ai: ai(for: state),
            aiHistory: FakeAIHistoryRepository(
                generations: [.aiAssistantEmpty, .aiHistoryEmpty].contains(state) ? [] : FakeAIHistoryRepository.seed
            ),
            account: FakeAccountRepository(),
            notifications: FakeNotificationCenter(permission: notificationPermission(for: state)),
            reminderSettings: ReminderSettingsStore(defaults: boardDefaults(for: state)),
            connectivity: FakeConnectivity(online: !offlineStates.contains(state)),
            cachesLists: false,
            filesDirectory: filesDirectory(for: state),
            cachesRegister: false,
            now: { clock(for: state) },
            fixedClock: true,
            bundleVersion: "1.0 (14)"
        )
    }

    /// The signed-in tutor and her centre for a state, with the failures a board draws.
    @MainActor static func session(for state: LaunchState) -> (FakeAuthRepository, FakeCentreRepository) {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        switch initialState(for: state) {
        case .needsOnboarding: auth.user = FakeAuthRepository.meera
        case .ready:
            auth.user = FakeAuthRepository.meera
            centres.workspace = workspace(for: state)
            if state == .settingsSaveFailed {
                // P7-Settings-SaveFailed: the centre's name does not save.
                centres.nextError = URLError(.notConnectedToInternet)
            }
            if state == .accountPasswordFailed || state == .deleteAccountFailed {
                // P7-Account-Password-Failed, P7-Delete-Failed: the write does not go through.
                auth.nextAccountFailure = .offline
            }
        case .loading, .signedOut: break
        }
        return (auth, centres)
    }

    /// A fresh folder per launch for the queue and the caches; the states that start with something in them write it.
    @MainActor static func filesDirectory(for state: LaunchState) -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("fixtures-\(state.rawValue)-\(UUID().uuidString)", isDirectory: true)
        if state == .accountSignOutPending {
            let queue = ChangeQueue(centre: meeraWorkspace.centre.id, directory: folder)
            for change in twoWaitingChanges {
                queue.add(change)
            }
        }
        keepCopies(for: state, in: folder)
        queueChanges(for: state, in: folder)
        return folder
    }

    /// P7-Account-SignOut-Pending's two changes: Class 10 Maths' attendance at 17:05 and Dev's fee at 17:12.
    static var twoWaitingChanges: [QueuedChange] {
        let today = Day(year: 2026, month: 10, day: 7) ?? Day(now, calendar: DayHeading.india)
        return [
            QueuedChange(
                kind: .attendance(
                    classID: FakeClassesRepository.maths.id, className: "Class 10 Maths", date: today, marks: [:],
                    present: 5, total: 6
                ),
                madeAt: india(day: 7, hour: 17, minute: 5)
            ),
            QueuedChange(
                kind: .markPaid(
                    invoiceID: FakeFeesRepository.devOctober, studentName: "Dev Kumar",
                    month: Period(year: 2026, month: 10), amount: Money(rupees: 1000), method: .upi,
                    paidAt: india(day: 7, hour: 17, minute: 12)
                ),
                madeAt: india(day: 7, hour: 17, minute: 12)
            ),
        ]
    }

    /// A fresh `UserDefaults` suite per launch, so a fixture's reminder choices never touch the iPhone's own.
    static func boardDefaults(for state: LaunchState) -> UserDefaults {
        let name = "fixtures-\(state.rawValue)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        if state == .remindersAllOff {
            // P7-Reminders-AllOff: allowed, every switch off.
            var off = ReminderSettings()
            off.classOn = false
            off.eventOn = false
            off.feesOn = false
            ReminderSettingsStore(defaults: defaults).save(off)
        }
        return defaults
    }

    /// What iOS answers about notifications: not asked yet or refused on those boards, allowed elsewhere.
    static func notificationPermission(for state: LaunchState) -> NotificationPermission {
        switch state {
        case .remindersNotAsked: .notAsked
        case .remindersRefused: .refused
        default: .allowed
        }
    }

    public static func initialState(for state: LaunchState) -> SessionStore.State {
        switch state {
        case .onboarding: .needsOnboarding(FakeAuthRepository.meera)
        case .todayEmpty, .laterStudents, .laterAttendance, .laterSchool, .laterMore, .settings, .studentsEmpty,
             .studentsFew,
             .students, .studentsSearching, .studentsFiltered, .studentsAddMenu, .studentNew, .studentNewFilled,
             .studentNewInvalid, .studentNewNewClass, .studentNewClassMade, .studentNewClass9, .studentNewClassPicker,
             .studentNewSchool, .studentNewEnd, .studentRecord, .studentEnd, .studentNotKnown, .studentLadder,
             .studentConsentAsk,
             .studentConsentRecord, .studentConsentWaiting, .textbookIntro, .textbookReading, .textbookChapters,
             .textbookChapterEdit, .student,
             .studentArchived,
             .studentArchiveConfirm, .studentDeleteConfirm,
             .studentEdit, .classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm,
             .classDetail, .classAddMembers, .attendance, .attendanceClassMenu, .attendanceExceptions,
             .attendanceSaveFailed,
             .attendanceSaved, .attendanceAlert, .attendancePast, .attendanceEmpty, .history, .historyByStudent,
             .historyStudent, .historyEmpty, .schedule, .scheduleDay, .eventNew, .eventEdit, .eventEditKeyboard,
             .eventGone,
             .eventDeleteConfirm, .tasks, .tasksEmpty, .today, .todayEvening, .todayNoClass,
             .todayAddingTask, .more, .feesEmpty, .fees, .feesLoadFailed, .feesDue, .feesPaid, .feesOverdue, .feesPayee,
             .feesGenerate,
             .feesGenerateNothing, .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind,
             .feesWaive, .studentFeesDue, .studentFees, .paymentsEmpty, .payments,
             .paymentsQR, .reports, .reportsAttendance, .reportsExport, .reportsEmpty, .todayAI, .aiAssistant,
             .aiAssistantEmpty, .aiPaper, .aiHomework, .aiWorksheet, .aiNote, .aiNoteStudent, .aiGenerating,
             .aiGenerateFailed, .aiResultPaper, .aiResultCopied, .aiResultRegenerating, .aiResultNote, .aiNoteSend,
             .aiHistory,
             .aiHistoryEmpty, .scanIntro, .scanConsent, .scanCameraRefused, .scanReading, .scanReview,
             .scanReviewScrolled, .scanReviewEdit,
             .scanReviewRemoved, .scanReviewLeave, .scanNothing, .scanFailed, .scanSaved, .checkIntro, .checkPages,
             .checkScheme, .checkSchemeTyped, .checkChecking, .checkResult, .checkMarkPicker, .checkResultEdited,
             .checkResultScrolled,
             .checkSaved, .checkFailed, .settingsEnd, .settingsSaveFailed, .help, .helpAnswer, .account,
             .accountPassword, .accountPasswordFailed, .accountPasswordSaved, .accountSignOut, .accountSignOutPending,
             .deleteAccount, .deleteAccountTyped, .deleteAccountDeleting, .deleteAccountFailed, .offlineToday,
             .offlineStudents, .offlineFees, .offlineNoCache, .offlineWriteRefused, .offlineAttendanceSaved,
             .offlineFeeMarked, .syncSending, .syncSent, .syncFailed, .pending, .pendingDiscard, .remindersNotAsked,
             .reminders, .remindersAllOff, .remindersRefused, .remindersDayPicker:
            .ready(workspace(for: state))
        case .placeholder, .kit, .kitFields, .kitSurfaces, .kitPatterns, .kitDialog, .kitPhase7, .signin, .signinEmail,
             .signinCode,
             .signinCodeWrong, .signinPassword, .signinDeleted: .signedOut
        }
    }

    /// The centre each state signs in to: the boards' Meera, her UPI id confirmed on 1 October; a fresh centre has no
    /// UPI id yet (P5-Fees-Empty); P5-Fees-Payee's id was never confirmed.
    public static func workspace(for state: LaunchState) -> Workspace {
        switch state {
        case .feesEmpty, .feesGenerate, .paymentsEmpty: FakeCentreRepository.meeraWorkspaceWithoutUPI
        case .feesPayee: FakeCentreRepository.meeraWorkspaceUnconfirmed
        case .scanIntro, .scanCameraRefused, .scanReading, .scanReview, .scanReviewScrolled, .scanReviewEdit,
             .scanReviewRemoved,
             .scanReviewLeave, .scanNothing, .scanFailed, .scanSaved: FakeCentreRepository.meeraWorkspaceConsented
        case _ where RootView.checkStates.contains(state): FakeCentreRepository.meeraWorkspaceConsented
        default: meeraWorkspace
        }
    }

    /// The fees each state starts with: none before anything exists; the boards' months otherwise.
    static func fees(for state: LaunchState) -> [FeeInvoice] {
        switch state {
        case .todayEmpty, .studentsEmpty, .attendanceEmpty, .classesEmpty, .feesEmpty, .feesGenerate: []
        default: FakeFeesRepository.seed
        }
    }

    /// The register each state starts with: nothing; the first three with no class; the seed's ten and two classes.
    static func register(for state: LaunchState) -> (students: [Student], classes: [Classroom]) {
        switch state {
        case .studentsEmpty, .classesEmpty, .attendanceEmpty, .todayEmpty: ([], [])
        case .studentsFew: (FakeStudentsRepository.few, [])
        case .studentArchived: (FakeStudentsRepository.seed.map(archivingAkshita), FakeClassesRepository.seed)
        case .scanSaved: (FakeStudentsRepository.seed + scannedSeven, FakeClassesRepository.seed)
        default: (FakeStudentsRepository.seed, FakeClassesRepository.seed)
        }
    }

    /// The saved attendance each state starts with: the seed's four weeks; History and the student detail also hold
    /// the 7th's Class 10 Maths (P4-History-*, P4-StudentDetail-Attendance). Saved and the alert save the 7th on
    /// screen, at their own clock.
    static func attendance(for state: LaunchState) -> [AttendanceSession] {
        switch state {
        case .history, .historyByStudent, .historyStudent, .student, .studentFeesDue, .studentFees, .schedule,
             .scheduleDay, .eventNew, .eventEdit, .eventEditKeyboard, .eventGone, .eventDeleteConfirm, .todayEvening,
             .reports,
             .reportsAttendance,
             .reportsExport, .reportsEmpty: FakeAttendanceRepository.seedWithToday
        case .historyEmpty: []
        default: FakeAttendanceRepository.seed
        }
    }

    /// Each state's clock: the boards' Wednesday at 18:30, or the minute a board names (P4-Attendance-Mark-Saved and
    /// P4-Absence-Alert are saved at 18:32).
    static func clock(for state: LaunchState) -> Date {
        switch state {
        case .attendanceSaved, .attendanceAlert: now.addingTimeInterval(2 * 60)
        case _ where RootView.aiStates.contains(state): now.addingTimeInterval(2 * 60)
        case .today, .todayAddingTask, .todayAI: india(day: 7, hour: 16, minute: 35)
        case _ where offlineStates.contains(state): offlineClock(state)
        case .syncSending, .syncSent, .syncFailed: india(day: 7, hour: 16, minute: 35)
        case .todayEvening: india(day: 7, hour: 19, minute: 30)
        case .todayNoClass: india(day: 10, hour: 9, minute: 30)
        default: now
        }
    }

    /// Today's tiles on the boards: ten students, ₹4,000 due (the seed's four unpaid), the classes meeting that day.
    static func counts(for state: LaunchState) -> TodayCounts {
        switch state {
        case .today, .todayEvening, .todayAddingTask, .todayAI, .syncSending, .syncSent, .syncFailed:
            TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)
        case .todayNoClass: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 0)
        default: .zero
        }
    }

    static func india(day: Int, hour: Int, minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? now
    }

    /// P3-StudentDetail-Archived: Akshita archived on the boards' day.
    private static func archivingAkshita(_ student: Student) -> Student {
        guard student.id == FakeStudentsRepository.akshita else { return student }
        var archived = student
        archived.archivedAt = now
        return archived
    }
}
