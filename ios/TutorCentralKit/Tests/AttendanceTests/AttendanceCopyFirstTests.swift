import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

/// The mark screen's one read path (D76): the day's copy at once (U27), a spinner by the date while the read runs and
/// no hint beside an error (U10), and the replayed day read again after the queue sent it (Phase 17's hand run 3).
@MainActor struct AttendanceCopyFirstTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("copy-first-\(UUID().uuidString)")
    let centre = FakeCentreRepository.meeraWorkspace.centre.id
    let hemanth = FakeAttendanceRepository.hemanth

    func make(_ attendance: FakeAttendanceRepository) async -> AttendanceStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: FakeMessageLogRepository(), now: { FakeCountsRepository.fixedNow }
        )
        let (centre, folder) = (centre, folder)
        store.cache = { CachedRead(centre: centre, key: "attendance-\($0.isoMonth)", directory: folder) }
        return store
    }

    var day: Day {
        FakeAttendanceRepository.seedWithToday[0].date
    }

    @Test func offlineAtLaunchTheDaysCopyShowsAtOnceWithTheSpinner() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)
        await make(attendance).open(classID: FakeClassesRepository.maths.id, date: day)
        attendance.delay = .seconds(5)
        attendance.nextError = URLError(.notConnectedToInternet)
        let store = await make(attendance)
        let open = Task { await store.open(classID: FakeClassesRepository.maths.id, date: day) }
        let until = ContinuousClock.now.advanced(by: .seconds(3))
        while !store.opened, ContinuousClock.now < until {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(store.opened && store.saved != nil && store.loading && store.savedAt != nil)
        open.cancel()
        await open.value
    }

    @Test func aFailedReadWithNothingSavedSaysSoAndShowsTheEmptyDay() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)
        attendance.nextError = URLError(.badServerResponse)
        let store = await make(attendance)
        await store.open(classID: FakeClassesRepository.maths.id, date: day)
        #expect(store.error == "Couldn't load attendance. Check your connection and try again.")
        #expect(store.opened && !store.loading)
    }

    @Test func afterAQueuedReplayTheOpenDayShowsTheReplayedAbsences() async throws {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await make(attendance)
        let queue = ChangeQueue(centre: centre, directory: folder)
        store.queue = queue
        store.online = { false }
        await store.load()
        store.toggle(hemanth)
        #expect(await store.save())
        // The queue sends it (as QueueRunner does) and leaves the queue.
        let change = try #require(queue.pending.changes.first)
        guard case let .attendance(classID, _, date, marks, _, _) = change.kind else {
            Issue.record("not attendance")
            return
        }
        _ = try await attendance.save(centre: centre, classID: classID, date: date, marks: marks)
        queue.removeSent(change)
        store.online = { true }
        await store.reload()
        #expect(store.saved?.marks[hemanth] == .absent && store.draft.marks[hemanth] == .absent)
        #expect(store.phase == .reopened(savedAt: FakeCountsRepository.fixedNow) || store
            .phase == .saved(at: FakeCountsRepository.fixedNow))
    }
}
