import Data
import Domain
import Foundation
import Students
import Testing
@testable import Attendance

@MainActor struct AttendanceStoreTests {
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
    let messages = FakeMessageLogRepository(logs: FakeMessageLogRepository.seed)
    let today = Day(year: 2026, month: 10, day: 7)!
    let maths = FakeClassesRepository.maths.id
    let hemanth = FakeAttendanceRepository.hemanth

    func make() async -> AttendanceStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: messages,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func opensTodayOnTheFirstClassWithEveryonePresent() async {
        let store = await make()
        #expect(store.draft.date == today && store.draft.classID == maths && store.className == "Class 10 Maths")
        #expect(store.members.map(\.name).first == "Akshita Rao" && store.members.count == 6 && store.draft
            .presentCount == 6)
        #expect(store.phase == .fresh && store.canSave && store.saveLabel == "Save attendance" && store.banner == nil)
        #expect(store.dateText == "Today, 7 Oct" && store.classOptions.map(\.name) == [
            "All students",
            "Class 10 Maths",
            "Class 8 Science",
        ])
        #expect(store.classOptions.map(\.count) == [10, 6, 3] && store.hasStudents)
    }

    @Test func savingWritesEveryMemberAndShowsTheAbsentOnes() async {
        let store = await make()
        store.toggle(hemanth)
        #expect(store.draft.absentCount == 1)
        #expect(await store.save())
        #expect(attendance.saves.count == 1 && attendance.saves[0].marks.count == 6 && attendance.saves[0]
            .marks[hemanth] == .absent)
        guard case .saved = store.phase else { Issue.record("not saved"); return }
        #expect(store.banner?.ok == true && store.banner?.text.hasPrefix("Saved at 18:30") == true)
        #expect(store.absentRows.map(\.student.name) == ["Hemanth Reddy"] && store.absentRows[0]
            .line == "Lakshmi Reddy · +91 93802 60871")
        #expect(store.absentRows[0].told == nil && !store.canSave && store.lastSavedAt != nil)
    }

    @Test func savingAgainReplacesTheMarks() async {
        let store = await make()
        store.toggle(hemanth)
        _ = await store.save()
        store.toggle(hemanth)
        #expect(store.canSave && store.saveLabel == "Save changes")
        _ = await store.save()
        #expect(attendance.saves.count == 2 && attendance.saves[1].marks[hemanth] == .present)
        #expect(attendance.sessions.filter { $0.date == today && $0.classID == maths }.count == 1 && store.absentRows
            .isEmpty)
    }

    @Test func aPastDayReopensWithItsMarksAndWhoWasTold() async throws {
        let store = await make()
        try await store.open(classID: maths, date: #require(Day(year: 2026, month: 10, day: 5)))
        guard case .reopened = store.phase else { Issue.record("not reopened"); return }
        #expect(store.draft.marks[hemanth] == .absent && store.draft.presentCount == 5 && !store.canSave)
        #expect(store.banner?.text == "Marked on Mon 5 Oct at 18:04. Saving again replaces it." && store.banner?
            .ok == false)
        #expect(store.absentRows[0].told == "Told Mon 5 Oct" && store.dateText == "Mon 5 Oct")
    }

    @Test func aNewMemberIsPresentOnReopen() async throws {
        let store = await make()
        var sessions = attendance.sessions
        let index = try #require(sessions.firstIndex { $0.date.day == 5 && $0.classID == maths })
        sessions[index].marks[FakeStudentsRepository.akshita] = nil
        attendance.sessions = sessions
        try await store.open(classID: maths, date: #require(Day(year: 2026, month: 10, day: 5)))
        #expect(store.draft.marks[FakeStudentsRepository.akshita] == .present && store.members.count == 6)
        #expect(!store.canSave, "a member without a mark is present, which is not a change the tutor made")
    }

    @Test func allStudentsIsItsOwnSession() async {
        let store = await make()
        await store.open(classID: nil, date: today)
        #expect(store.members.count == 10 && store.className == "All students" && store.draft.classID == nil)
        _ = await store.save()
        #expect(attendance.saves.last?.classID == nil && attendance.saves.last?.marks.count == 10)
    }

    @Test func aFailedSaveKeepsTheMarksAndOffersRetry() async {
        let store = await make()
        store.toggle(hemanth)
        attendance.nextError = URLError(.notConnectedToInternet)
        #expect(await store.save() == false)
        #expect(store.draft.marks[hemanth] == .absent && store.phase == .fresh && store.canSave)
        #expect(store.message == "Couldn't save attendance. Check your connection and try again." && store.canRetry)
        await store.retryLast()
        #expect(attendance.saves.count == 1, "the failed attempt never reached the fake; the retry did")
        guard case .saved = store.phase else { Issue.record("not saved after retry"); return }
    }

    @Test func tellingAParentLogsOnce() async throws {
        let store = await make()
        store.toggle(hemanth)
        _ = await store.save()
        let alert = try #require(store.alert(for: hemanth))
        #expect(alert.text
            .hasPrefix("Hello Lakshmi, Hemanth was absent from Class 10 Maths today, Wednesday 7 October."))
        #expect(alert.url?.host() == "wa.me" && alert.parentLine == "Lakshmi Reddy · +91 93802 60871")
        let url = await store.tell(hemanth)
        #expect(url == alert.url && messages.logged == [hemanth] && store.absentRows[0].told == "Told today")
        #expect(store.alert(for: hemanth) == nil, "told: the row shows the mark, not the button")
    }

    @Test func aStudentWithoutANumberCannotBeTold() async {
        let store = await make()
        await store.open(classID: nil, date: today)
        var students = FakeStudentsRepository.seed
        students[9].parentPhone = nil // Sahil Verma
        let sahil = students[9].id
        // The register is shared: change it as a refresh would.
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let noNumber = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: messages,
            now: { FakeCountsRepository.fixedNow }
        )
        await noNumber.open(classID: nil, date: today)
        noNumber.toggle(sahil)
        _ = await noNumber.save()
        let alert = noNumber.alert(for: sahil)
        #expect(alert?.url == nil && alert?.parentLine == "Add the parent's number first")
        #expect(await noNumber.tell(sahil) == nil && messages.logged.isEmpty)
    }

    @Test func noStudentsIsTheEmptyState() async {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(),
            classes: FakeClassesRepository(),
            cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            register: register,
            attendance: attendance,
            messages: messages,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        #expect(!store.hasStudents && store.members.isEmpty && store.draft.classID == nil)
    }

    @Test func aSecondLoadKeepsTheUnsavedToggles() async {
        let store = await make()
        #expect(store.opened)
        store.toggle(hemanth)
        await store.load()
        #expect(store.draft.marks[hemanth] == .absent, "coming back to the tab keeps what the tutor marked")
    }

    @Test func theAlertSaysWhenTheChildWasAbsent() async throws {
        let store = await make()
        store.toggle(hemanth)
        _ = await store.save()
        #expect(try #require(store.alert(for: hemanth)).headline == "Hemanth was absent today")
        try await store.open(classID: maths, date: #require(Day(year: 2026, month: 10, day: 2)))
        let earlier = try #require(store.absentRows.first)
        #expect(try #require(store.alert(for: earlier.student.id)).headline.hasSuffix("was absent on Fri 2 Oct"))
    }

    @Test func aLinkOpenedBeforeTheTabLoadsWins() async throws {
        // tutorcentral://attendance?date=…: AppShell asks for the day, then the tab appears and loads.
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        attendance.delay = .milliseconds(50)
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: messages, now: { FakeCountsRepository.fixedNow }
        )
        let monday = try #require(Day(year: 2026, month: 10, day: 5))
        async let linked: Void = store.open(classID: maths, date: monday)
        await store.load()
        await linked
        #expect(store.draft.date == monday && store.draft.classID == maths)
    }

    @Test func aLinkArrivingWhileTheTabLoadsWins() async throws {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        attendance.delay = .milliseconds(50)
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: attendance,
            messages: messages, now: { FakeCountsRepository.fixedNow }
        )
        let monday = try #require(Day(year: 2026, month: 9, day: 28))
        async let loading: Void = store.load()
        try await Task.sleep(for: .milliseconds(10))
        await store.open(classID: maths, date: monday)
        await loading
        #expect(store.draft.date == monday, "the newest open wins")
    }

    @Test func aLaterOpenWinsOverASlowerEarlierOne() async throws {
        // September's read is slow, October's fast: the day chosen second must be the one shown.
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let slowSeptember = MonthDelayAttendance(
            sessions: FakeAttendanceRepository.seed,
            slow: Period(year: 2026, month: 9)
        )
        let store = AttendanceStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, attendance: slowSeptember,
            messages: messages, now: { FakeCountsRepository.fixedNow }
        )
        let first = try #require(Day(year: 2026, month: 9, day: 28))
        let second = try #require(Day(year: 2026, month: 10, day: 5))
        async let earlier: Void = store.open(classID: maths, date: first)
        try await Task.sleep(for: .milliseconds(10))
        await store.open(classID: maths, date: second)
        await earlier
        #expect(store.draft.date == second && store.saved?.date == second)
    }
}

/// Attendance whose read of one month is slow, so two opens finish in the other order.
@MainActor final class MonthDelayAttendance: AttendanceRepository {
    let fake: FakeAttendanceRepository
    let slow: Period

    init(sessions: [AttendanceSession], slow: Period) {
        fake = FakeAttendanceRepository(sessions: sessions)
        self.slow = slow
    }

    func sessions(centre: UUID, month: Period) async throws -> [AttendanceSession] {
        if month == slow {
            try await Task.sleep(for: .milliseconds(150))
        }
        return try await fake.sessions(centre: centre, month: month)
    }

    func save(
        centre: UUID,
        classID: UUID?,
        date: Day,
        marks: [UUID: AttendanceStatus]
    ) async throws -> AttendanceSession {
        try await fake.save(centre: centre, classID: classID, date: date, marks: marks)
    }
}
