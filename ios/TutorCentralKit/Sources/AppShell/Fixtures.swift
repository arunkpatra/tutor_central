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
        let students = FakeStudentsRepository(students: students(for: state))
        let fees = FakeFeesRepository(invoices: fees(for: state), now: { clock(for: state) })
        let attendance = FakeAttendanceRepository(sessions: attendance(for: state), now: { clock(for: state) })
        scriptFailures(for: state, counts: counts, students: students, fees: fees, attendance: attendance)
        let (plans, schoolItems, textbooks) = (plans(for: state), schoolItems(for: state), textbooks(for: state))
        let server = PlanServer(
            plans: plans, textbooks: textbooks, attendance: attendance, schoolItems: schoolItems,
            students: students.students, classes: register(for: state).classes, now: { clock(for: state) }
        )
        return Dependencies(
            auth: auth,
            centres: centres,
            counts: counts,
            students: students,
            classes: FakeClassesRepository(classes: register(for: state).classes),
            attendance: attendance,
            messages: messages(for: state),
            schools: FakeSchoolsRepository(schools: boardSchools),
            schoolItems: schoolItems,
            textbooks: textbooks,
            record: record(for: state),
            plans: plans, photos: photos(for: state),
            events: FakeEventsRepository(events: state == .todayEmpty ? [] : FakeEventsRepository.seed),
            tasks: FakeTasksRepository(tasks: [.tasksEmpty, .todayEmpty].contains(state) ? [] : FakeTasksRepository
                .seed),
            fees: fees,
            qrImages: MemoryQRImageStore(images: state == .paymentsQR ? [meeraWorkspace.centre.id: sampleQR()] : [:]),
            ai: ai(for: state),
            aiHistory: FakeAIHistoryRepository(
                generations: [.makeEmpty, .aiHistoryEmpty].contains(state) ? [] : FakeAIHistoryRepository.seed
            ),
            account: FakeAccountRepository(),
            notifications: FakeNotificationCenter(permission: notificationPermission(for: state)),
            reminderSettings: reminderSettings(for: state),
            deviceTokens: FakeDeviceTokenRepository(),
            jobs: jobs(for: state, server: server),
            connectivity: FakeConnectivity(online: !offlineStates.contains(state)),
            cachesLists: false,
            filesDirectory: filesDirectory(for: state),
            cachesRegister: false,
            now: { clock(for: state) },
            fixedClock: true,
            bundleVersion: "1.0 (14)"
        )
    }

    /// The books each board draws: the evening's, the note day's, the one not on track, or the seed's.
    @MainActor static func textbooks(for state: LaunchState) -> FakeTextbooksRepository {
        state == .noteCanDoNoChange || makeStates.contains(state) || progressStates.contains(state)
            ? FakeTextbooksRepository.evening()
            : noteDayStates.contains(state) ? noteDayTextbooks()
            : notOnTrackStates.contains(state) ? FakeTextbooksRepository.notOnTrack()
            : closeStates.contains(state) || planStates.contains(state) || examPageStates.contains(state)
            ? FakeTextbooksRepository.evening()
            : FakeTextbooksRepository.seeded(riyasMaths: state == .placement)
    }

    /// The register's students with their schools' languages, and their parents where the board names them.
    static func students(for state: LaunchState) -> [Student] {
        let listed = withSchoolLanguages(register(for: state).students, for: state)
        let parents = noteDayStates.contains(state) || notOnTrackStates.contains(state) || marksStates.contains(state)
            || state == .todayAfterClose
        return parents ? withParents(listed, for: state) : listed
    }

    /// The failures a board draws: a month that does not load, a refused save, every read offline.
    @MainActor static func scriptFailures(
        for state: LaunchState, counts: FakeCountsRepository, students: FakeStudentsRepository,
        fees: FakeFeesRepository, attendance: FakeAttendanceRepository
    ) {
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

    /// The tutor's reminder choices with the account (P18-Reminders: 15 minutes before a class, the next at 16:45
    /// today); every switch off on P7-Reminders-AllOff.
    static func reminderSettings(for state: LaunchState) -> FakeReminderSettingsRepository {
        var settings = ReminderSettings()
        if state == .remindersAllOff {
            settings.classOn = false
            settings.eventOn = false
            settings.feesOn = false
            settings.planReady = false
            settings.notesReady = false
        } else {
            settings.classMinutesBefore = 15
        }
        let next = DayHeading.india.date(bySettingHour: 16, minute: 45, second: 0, of: clock(for: state))
        return FakeReminderSettingsRepository(
            kept: settings, next: next.map { NextReminder(subject: "Class 10 Maths", at: $0) }
        )
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
        case .placeholder, .kit, .kitFields, .kitSurfaces, .kitPatterns, .kitDialog, .kitPhase7, .signin, .signinEmail,
             .signinCode, .signinCodeWrong, .signinPassword, .signinDeleted: .signedOut
        // Every other state is a signed-in centre's screen.
        default: .ready(workspace(for: state))
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

    /// The saved attendance each state starts with: the seed's four weeks; History and the student detail also hold
    /// the 7th's Class 10 Maths (P4-History-*, P4-StudentDetail-Attendance). Saved and the alert save the 7th on
    /// screen, at their own clock.
    static func attendance(for state: LaunchState) -> [AttendanceSession] {
        switch state {
        case .history, .historyByStudent, .historyStudent, .student, .studentFeesDue, .studentFees, .schedule,
             .scheduleDay, .eventNew, .eventEdit, .eventEditKeyboard, .eventGone, .eventDeleteConfirm, .todayEvening,
             .reports,
             .reportsAttendance,
             .reportsExport, .reportsEmpty,
             _ where progressStates.contains(state): FakeAttendanceRepository.seedWithToday
        case .historyEmpty: []
        case .todayAfterClose: FakeAttendanceRepository.seedWithEveningClosed
        case _ where noteDayStates.contains(state): noteDaySessions
        default: FakeAttendanceRepository.seed
        }
    }

    /// Each state's clock: the boards' Wednesday at 18:30, or the minute a board names (P4-Attendance-Mark-Saved and
    /// P4-Absence-Alert are saved at 18:32).
    static func clock(for state: LaunchState) -> Date {
        if let today = todayClock(state) {
            return today
        }
        return switch state {
        case .attendanceSaved, .attendanceAlert: now.addingTimeInterval(2 * 60)
        case _ where RootView.aiStates.contains(state): now.addingTimeInterval(2 * 60)
        case _ where offlineStates.contains(state): offlineClock(state)
        case .syncSending, .syncSent, .syncFailed: india(day: 7, hour: 16, minute: 35)
        case _ where closeStates.contains(state): india(day: 7, hour: 17, minute: 5)
        case _ where notOnTrackStates.contains(state): notOnTrackClock
        default: now
        }
    }

    /// Today's tiles on the boards: ten students, ₹4,000 due (the seed's four unpaid), the classes meeting that day.
    static func counts(for state: LaunchState) -> TodayCounts {
        switch state {
        case .today, .todayEvening, .todayAddingTask, .todayAI, .todayAfterClose, .syncSending, .syncSent, .syncFailed:
            TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)
        case _ where planStates.contains(state): TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)
        case .todayNoBatch: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 0)
        case _ where noteDayStates.contains(state): TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 0)
        case .todayNotOnTrack: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)
        default: .zero
        }
    }

    /// P3-StudentDetail-Archived: Akshita archived on the boards' day.
    private static func archivingAkshita(_ student: Student) -> Student {
        guard student.id == FakeStudentsRepository.akshita else { return student }
        var archived = student
        archived.archivedAt = now
        return archived
    }
}

extension Fixtures {
    static func india(day: Int, hour: Int, minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)) ?? now
    }

    /// Today's states' clocks: the plan's at 16:35, after the close at 18:40, the evening at 19:30, Saturday's 09:30.
    static func todayClock(_ state: LaunchState) -> Date? {
        switch state {
        case .todayAfterClose: india(day: 7, hour: 18, minute: 40)
        case .today, .todayAddingTask, .todayAI, .todayPlanFailed: india(day: 7, hour: 16, minute: 35)
        case .todayPlanMaking: india(day: 7, hour: 6, minute: 5)
        case _ where planStates.contains(state): india(day: 7, hour: 16, minute: 35)
        case _ where lastDaysStates.contains(state): india(day: 14, hour: 19, minute: 0)
        case .todayNoBatch: india(day: 10, hour: 9, minute: 30)
        case .todayEvening: india(day: 7, hour: 19, minute: 30)
        case _ where noteDayStates.contains(state): noteDayClock
        default: nil
        }
    }
}

extension Fixtures {
    /// The register each state starts with: nothing; the first three with no class; the seed's ten and two classes.
    static func register(for state: LaunchState) -> (students: [Student], classes: [Classroom]) {
        if progressStates.contains(state) {
            // The review's R-app-9: a centre before its first student.
            return state == .reportsProgressEmpty ? ([], []) : (progressStudents, FakeClassesRepository.withEvening)
        }
        // Check a paper's boards mark Hemanth's paper: his parent has agreed (D62).
        let board = boardRegister(state)
        let agreed = RootView.checkStates.contains(state) && state != .checkConsentWaiting
        return agreed ? (board.students.map(agreeing), board.classes) : board
    }

    /// A student whose parent's consent is recorded (the boards' moment).
    static func agreeing(_ student: Student) -> Student {
        var agreed = student
        agreed.consent = student.parentPhone.map { ConsentRecord(at: now, phone: $0, how: .whatsapp) }
        return agreed
    }

    private static func boardRegister(_ state: LaunchState) -> (students: [Student], classes: [Classroom]) {
        switch state {
        case .studentsEmpty, .classesEmpty, .attendanceEmpty, .todayEmpty: ([], [])
        case .studentsFew: (FakeStudentsRepository.few, [])
        case .studentArchived: (FakeStudentsRepository.seed.map(archivingAkshita), FakeClassesRepository.seed)
        case .scanSaved: (FakeStudentsRepository.seed + scannedSeven, FakeClassesRepository.seed)
        // P12-Form-Paper-NoClass: no student has a class yet and there is no batch, so the paper starts on none.
        case .aiPaperNoClass: (FakeStudentsRepository.seed.map(withoutClass), [])
        case _ where planStates.contains(state) || examPageStates.contains(state) || state == .todayNoBatch: (
                planStudents, [FakeClassesRepository.science, FakeClassesRepository.evening]
            )
        case .closeCards: (cardStudents, FakeClassesRepository.withEvening)
        case _ where notOnTrackStates.contains(state): (
                notOnTrackStudents, [FakeClassesRepository.science, FakeClassesRepository.evening]
            )
        case _ where noteDayStates.contains(state) || closeStates.contains(state) || makeStates.contains(state): (
                eveningStudents(for: state),
                FakeClassesRepository.withEvening
            )
        default: (FakeStudentsRepository.seed, FakeClassesRepository.seed)
        }
    }
}

extension Fixtures {
    /// The Evening batch's register; Riya before her class is set in `make-sheet-no-class` (the review's R-app-2).
    static func eveningStudents(for state: LaunchState) -> [Student] {
        guard state == .makeSheetNoClass else { return FakeStudentsRepository.eveningSeed }
        return FakeStudentsRepository.eveningSeed.map { $0.id == FakeStudentsRepository.riya ? withoutClass($0) : $0 }
    }

    /// A student as entered before their class was set.
    static func withoutClass(_ student: Student) -> Student {
        var unset = student
        unset.classLevel = nil
        unset.classID = nil
        return unset
    }
}
