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
            centres.workspace = meeraWorkspace
        case .loading, .signedOut: break
        }
        return Dependencies(
            auth: auth,
            centres: centres,
            counts: FakeCountsRepository(),
            students: FakeStudentsRepository(students: register(for: state).students),
            classes: FakeClassesRepository(classes: register(for: state).classes),
            attendance: FakeAttendanceRepository(sessions: attendance(for: state)),
            messages: FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            events: FakeEventsRepository(events: FakeEventsRepository.seed),
            tasks: FakeTasksRepository(tasks: FakeTasksRepository.seed),
            cachesRegister: false,
            now: { now },
            bundleVersion: "0.1 (12)"
        )
    }

    public static func initialState(for state: LaunchState) -> SessionStore.State {
        switch state {
        case .onboarding: .needsOnboarding(FakeAuthRepository.meera)
        case .todayEmpty, .laterStudents, .laterFees, .laterAttendance, .laterMore, .settings, .studentsEmpty,
             .studentsFew,
             .students, .studentsSearching, .studentsFiltered, .studentsAddMenu, .studentNew, .studentNewFilled,
             .studentNewInvalid, .student, .studentArchived, .studentArchiveConfirm, .studentDeleteConfirm,
             .studentEdit, .classesEmpty, .classes, .classNew, .classEdit, .classArchiveConfirm,
             .classDetail, .classAddMembers: .ready(meeraWorkspace)
        case .placeholder, .kit, .kitFields, .kitSurfaces, .kitPatterns, .kitDialog, .signin, .signinEmail, .signinCode,
             .signinCodeWrong, .signinPassword: .signedOut
        }
    }

    /// The register each state starts with: nothing; the first three with no class; the seed's ten and two classes.
    static func register(for state: LaunchState) -> (students: [Student], classes: [Classroom]) {
        switch state {
        case .studentsEmpty, .classesEmpty: ([], [])
        case .studentsFew: (FakeStudentsRepository.few, [])
        case .studentArchived: (FakeStudentsRepository.seed.map(archivingAkshita), FakeClassesRepository.seed)
        default: (FakeStudentsRepository.seed, FakeClassesRepository.seed)
        }
    }

    /// The saved attendance each state starts with: the seed's four weeks (the states after a save add the 7th's).
    static func attendance(for _: LaunchState) -> [AttendanceSession] {
        FakeAttendanceRepository.seed
    }

    /// P3-StudentDetail-Archived: Akshita archived on the boards' day.
    private static func archivingAkshita(_ student: Student) -> Student {
        guard student.id == FakeStudentsRepository.akshita else { return student }
        var archived = student
        archived.archivedAt = now
        return archived
    }
}
