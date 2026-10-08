import Data
import Domain
import Foundation

/// What `bun shots <state>` launches: the fakes, filled with the boards' data, and a fixed clock, so every picture is
/// the same every time and matches its board.
public enum Fixtures {
    /// Wednesday 7 October 2026, 18:30 in India: "Good evening, Meera".
    public static let now = FakeCountsRepository.fixedNow

    public static let meeraWorkspace = FakeCentreRepository.meeraWorkspace

    @MainActor public static func dependencies(for state: LaunchState) -> Dependencies {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        switch initialState(for: state) {
        case .needsOnboarding: auth.user = FakeAuthRepository.meera
        case .ready:
            auth.user = FakeAuthRepository.meera
            centres.workspace = workspace(for: state)
        case .loading, .signedOut: break
        }
        return Dependencies(
            auth: auth,
            centres: centres,
            counts: FakeCountsRepository(counts: counts(for: state)),
            students: FakeStudentsRepository(students: register(for: state).students),
            classes: FakeClassesRepository(classes: register(for: state).classes),
            attendance: FakeAttendanceRepository(sessions: attendance(for: state), now: { clock(for: state) }),
            messages: FakeMessageLogRepository(
                logs: FakeMessageLogRepository.seed, feeLogs: FakeMessageLogRepository.feeSeed,
                now: { clock(for: state) }
            ),
            events: FakeEventsRepository(events: state == .todayEmpty ? [] : FakeEventsRepository.seed),
            tasks: FakeTasksRepository(tasks: [.tasksEmpty, .todayEmpty].contains(state) ? [] : FakeTasksRepository
                .seed),
            fees: FakeFeesRepository(invoices: fees(for: state), now: { clock(for: state) }),
            qrImages: MemoryQRImageStore(images: state == .paymentsQR ? [meeraWorkspace.centre.id: sampleQR()] : [:]),
            ai: ai(for: state),
            aiHistory: FakeAIHistoryRepository(
                generations: [.aiAssistantEmpty, .aiHistoryEmpty].contains(state) ? [] : FakeAIHistoryRepository.seed
            ),
            cachesRegister: false,
            now: { clock(for: state) },
            fixedClock: true,
            bundleVersion: "0.1 (12)"
        )
    }

    public static func initialState(for state: LaunchState) -> SessionStore.State {
        switch state {
        case .onboarding: .needsOnboarding(FakeAuthRepository.meera)
        case .todayEmpty, .laterStudents, .laterAttendance, .laterMore, .settings, .studentsEmpty,
             .studentsFew,
             .students, .studentsSearching, .studentsFiltered, .studentsAddMenu, .studentNew, .studentNewFilled,
             .studentNewInvalid, .student, .studentArchived, .studentArchiveConfirm, .studentDeleteConfirm,
             .studentEdit, .classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm,
             .classDetail, .classAddMembers, .attendance, .attendanceClassMenu, .attendanceExceptions,
             .attendanceSaved, .attendanceAlert, .attendancePast, .attendanceEmpty, .history, .historyByStudent,
             .historyStudent, .historyEmpty, .schedule, .scheduleDay, .eventNew, .eventEdit,
             .eventDeleteConfirm, .tasks, .tasksEmpty, .today, .todayEvening, .todayNoClass,
             .todayAddingTask, .more, .feesEmpty, .fees, .feesDue, .feesPaid, .feesOverdue, .feesPayee, .feesGenerate,
             .feesGenerateNothing, .feesMarkPaid, .feesMarkedPaid, .feesReceipt, .feesRemind,
             .feesWaive, .studentFeesDue, .studentFees, .paymentsEmpty, .payments,
             .paymentsQR, .reports, .reportsAttendance, .reportsExport, .reportsEmpty, .todayAI, .aiAssistant,
             .aiAssistantEmpty, .aiPaper, .aiHomework, .aiWorksheet, .aiNote, .aiNoteStudent, .aiGenerating,
             .aiGenerateFailed, .aiResultPaper, .aiResultRegenerating, .aiResultNote, .aiNoteSend, .aiHistory,
             .aiHistoryEmpty: .ready(workspace(for: state))
        case .placeholder, .kit, .kitFields, .kitSurfaces, .kitPatterns, .kitDialog, .signin, .signinEmail, .signinCode,
             .signinCodeWrong, .signinPassword: .signedOut
        }
    }

    /// The centre each state signs in to: the boards' Meera, her UPI id confirmed on 1 October; a fresh centre has no
    /// UPI id yet (P5-Fees-Empty); P5-Fees-Payee's id was never confirmed.
    public static func workspace(for state: LaunchState) -> Workspace {
        switch state {
        case .feesEmpty, .feesGenerate, .paymentsEmpty: FakeCentreRepository.meeraWorkspaceWithoutUPI
        case .feesPayee: FakeCentreRepository.meeraWorkspaceUnconfirmed
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
        default: (FakeStudentsRepository.seed, FakeClassesRepository.seed)
        }
    }

    /// The saved attendance each state starts with: the seed's four weeks; History and the student detail also hold
    /// the 7th's Class 10 Maths (P4-History-*, P4-StudentDetail-Attendance). Saved and the alert save the 7th on
    /// screen, at their own clock.
    static func attendance(for state: LaunchState) -> [AttendanceSession] {
        switch state {
        case .history, .historyByStudent, .historyStudent, .student, .studentFeesDue, .studentFees, .schedule,
             .scheduleDay, .eventNew, .eventEdit, .eventDeleteConfirm, .todayEvening, .reports, .reportsAttendance,
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
        case .todayEvening: india(day: 7, hour: 19, minute: 30)
        case .todayNoClass: india(day: 10, hour: 9, minute: 30)
        default: now
        }
    }

    /// Today's tiles on the boards: ten students, ₹4,000 due (the seed's four unpaid), the classes meeting that day.
    static func counts(for state: LaunchState) -> TodayCounts {
        switch state {
        case .today, .todayEvening, .todayAddingTask, .todayAI:
            TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1)
        case .todayNoClass: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 0)
        default: .zero
        }
    }

    private static func india(day: Int, hour: Int, minute: Int) -> Date {
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
