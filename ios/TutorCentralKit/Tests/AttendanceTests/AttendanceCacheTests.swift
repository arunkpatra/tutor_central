import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct AttendanceCacheTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("attendance-\(UUID().uuidString)")
    let centre = FakeCentreRepository.meeraWorkspace.centre.id

    func register() async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        return register
    }

    @Test func historyOfflineShowsTheSavedMonth() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)
        func make() async -> HistoryStore {
            let store = await HistoryStore(
                workspace: FakeCentreRepository.meeraWorkspace, register: register(), attendance: attendance,
                now: { FakeCountsRepository.fixedNow }
            )
            let (centre, folder) = (centre, folder)
            store.cache = { CachedRead(centre: centre, key: "history-\($0.isoMonth)", directory: folder) }
            return store
        }
        await make().load()
        attendance.nextError = URLError(.notConnectedToInternet)
        let offline = await make()
        await offline.load()
        #expect(offline.summary != nil && offline.savedAt != nil && offline.offlineRead && offline.error == nil)
    }

    @Test func theMarkScreenOfflineShowsTheSavedMonthsSessions() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)
        func make() async -> AttendanceStore {
            let store = await AttendanceStore(
                workspace: FakeCentreRepository.meeraWorkspace, register: register(), attendance: attendance,
                messages: FakeMessageLogRepository(), now: { FakeCountsRepository.fixedNow }
            )
            let (centre, folder) = (centre, folder)
            store.cache = { CachedRead(centre: centre, key: "attendance-\($0.isoMonth)", directory: folder) }
            return store
        }
        await make().open(classID: FakeClassesRepository.maths.id, date: FakeAttendanceRepository.seedWithToday[0].date)
        attendance.nextError = URLError(.notConnectedToInternet)
        let offline = await make()
        await offline.open(
            classID: FakeClassesRepository.maths.id,
            date: FakeAttendanceRepository.seedWithToday[0].date
        )
        #expect(offline.saved != nil && offline.savedAt != nil && offline.offlineRead && offline.error == nil)
    }
}
