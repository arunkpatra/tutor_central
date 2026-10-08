import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct RegisterStoreTests {
    let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
    let classes = FakeClassesRepository(classes: FakeClassesRepository.seed)

    func make(cache: RegisterCache? = nil) -> RegisterStore {
        RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: students,
            classes: classes,
            cache: cache,
            now: { FakeCountsRepository.fixedNow }
        )
    }

    func tempCache() -> RegisterCache {
        RegisterCache.forCentre(
            FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        )
    }

    @Test func loadsTheRegisterAndCountsIt() async {
        let store = make()
        await store.load()
        #expect(store.students.count == 10 && store.classes.count == 2 && !store.loading && store.error == nil)
        #expect(store.visible.map(\.name).first == "Akshita Rao" && store.countLine == "10 students" && store
            .showsFilters)
        #expect(store.period == Period(year: 2026, month: 10) && store.today == Day(year: 2026, month: 10, day: 7))
    }

    @Test func theQueryDrivesTheListAndTheCountLine() async {
        let store = make()
        await store.load()
        store.filter = .classroom(FakeClassesRepository.science.id)
        #expect(store.visible.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"] && store
            .countLine == "3 in Class 8 Science")
        store.filter = .unassigned
        #expect(store.visible.map(\.name) == ["Sahil Verma"] && store.countLine == "1 with no class")
        store.filter = .all
        store.search = "sh"
        // "sh" is in Lakshmi too: the board drew three rows, the rule (any part of the name) finds four.
        #expect(store.visible.map(\.name) == ["Akshita Rao", "Lakshmi Menon", "Meher Shah", "Riya Sharma"])
        #expect(store.countLine == "4 of 10 match" && store.isSearching)
        store.search = ""
        store.sort = .fee
        #expect(store.visible.first?.name == "Riya Sharma")
    }

    @Test func rowDetailIsTheClassThenThePhoneWhenItMatched() async throws {
        let store = make()
        await store.load()
        let akshita = try #require(store.student(FakeStudentsRepository.akshita))
        #expect(store.rowDetail(for: akshita) == "Class 10 Maths")
        store.search = "97991"
        #expect(store.rowDetail(for: akshita) == "+91 97991 13211")
        let sahil = try #require(store.students.first { $0.name == "Sahil Verma" })
        store.search = ""
        #expect(store.rowDetail(for: sahil) == "No class yet")
    }

    @Test func withNoClassesTheRowShowsThePhoneAndNoFilters() async {
        students.students = FakeStudentsRepository.few
        classes.classes = []
        let store = make()
        await store.load()
        #expect(!store.showsFilters && store.rowDetail(for: store.students[0]) == store.students[0].parentPhone!
            .display)
        #expect(store.countLine == "3 students")
    }

    @Test func theCacheShowsFirstThenTheNetworkReplacesIt() async throws {
        let cache = tempCache()
        var old = FakeStudentsRepository.few
        old[0].name = "Cached Dev"
        try cache.save(RegisterSnapshot(students: old, classes: [], period: Period(year: 2026, month: 10)))
        students.delay = .milliseconds(200)
        let store = make(cache: cache)
        let load = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(50))
        #expect(store.students.first?.name == "Cached Dev" && store.refreshing && !store.loading)
        await load.value
        #expect(store.students.count == 10 && !store.refreshing && cache.load()?.students.count == 10)
    }

    @Test func aCachedSnapshotFromAnotherMonthDropsItsFeeMarks() async throws {
        let cache = tempCache()
        try cache.save(RegisterSnapshot(
            students: FakeStudentsRepository.seed,
            classes: FakeClassesRepository.seed,
            period: Period(year: 2026, month: 9)
        ))
        students.nextError = URLError(.notConnectedToInternet)
        let store = make(cache: cache)
        await store.load()
        #expect(store.students.allSatisfy { $0.thisMonth == nil } && store
            .error == "Couldn't refresh. Check your connection and try again.")
    }

    @Test func aFailedRefreshKeepsTheRowsAndSaysSo() async {
        let store = make()
        await store.load()
        students.nextError = URLError(.notConnectedToInternet)
        await store.refresh()
        #expect(store.students.count == 10 && store.error == "Couldn't refresh. Check your connection and try again.")
        await store.refresh()
        #expect(store.error == nil)
    }

    @Test func addingAStudentIsOptimisticAndTheServersRowReplacesIt() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Zara Khan"
        draft.classID = FakeClassesRepository.maths.id
        students.delay = .milliseconds(100)
        let add = Task { await store.addStudent(draft) }
        try? await Task.sleep(for: .milliseconds(20))
        #expect(store.students.count == 11 && store.visible.last?.name == "Zara Khan")
        let made = await add.value
        #expect(made != nil && store.students.count == 11 && store.students.contains { $0.id == made!.id } && students
            .created == [draft])
    }

    @Test func aFailedAddRevertsTheRowAndOffersRetry() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        students.nextError = URLError(.notConnectedToInternet)
        let made = await store.addStudent(draft)
        #expect(made == nil && store.students.count == 10)
        #expect(store.message == "Couldn't save Riya. Check your connection and try again." && store.canRetry)
    }

    @Test func retryWritesOnce() async {
        let store = make()
        await store.load()
        var draft = StudentDraft()
        draft.name = "Riya Sharma"
        students.nextError = URLError(.notConnectedToInternet)
        await store.addStudent(draft)
        await store.retryLast()
        // The fake records what reached it: the failed attempt never did, the retry did once.
        #expect(store.students.count == 11 && students.created.count == 1 && !store.canRetry && store.message == nil)
        await store.retryLast()
        #expect(students.created.count == 1, "nothing to retry twice")
    }

    @Test func editArchiveRestoreAndDeleteFollowTheRepository() async throws {
        let store = make()
        await store.load()
        var draft = try StudentDraft(#require(store.student(FakeStudentsRepository.akshita)))
        draft.notes = "Board exam in March."
        #expect(await store.updateStudent(FakeStudentsRepository.akshita, with: draft))
        #expect(store.student(FakeStudentsRepository.akshita)?.notes == "Board exam in March.")
        await store.setArchived(FakeStudentsRepository.akshita, true)
        #expect(store.student(FakeStudentsRepository.akshita)?.isArchived == true && store.visible.count == 9 && store
            .countLine == "9 students")
        store.filter = .archived
        #expect(store.visible.map(\.name) == ["Akshita Rao"] && store.countLine == "1 archived")
        await store.setArchived(FakeStudentsRepository.akshita, false)
        #expect(store.student(FakeStudentsRepository.akshita)?.isArchived == false)
        store.filter = .all
        #expect(await store.deleteStudent(FakeStudentsRepository.akshita))
        #expect(store.student(FakeStudentsRepository.akshita) == nil && students
            .deleted == [FakeStudentsRepository.akshita])
    }

    @Test func aFailedEditRollsBackAndAFailedDeleteKeepsTheStudent() async throws {
        let store = make()
        await store.load()
        students.nextError = URLError(.notConnectedToInternet)
        var draft = try StudentDraft(#require(store.student(FakeStudentsRepository.akshita)))
        draft.name = "Akshita R"
        #expect(await store.updateStudent(FakeStudentsRepository.akshita, with: draft) == false)
        #expect(store.student(FakeStudentsRepository.akshita)?.name == "Akshita Rao" && store
            .message == "Couldn't save Akshita. Check your connection and try again.")
        students.nextError = URLError(.notConnectedToInternet)
        #expect(await store.deleteStudent(FakeStudentsRepository.akshita) == false)
        #expect(store.student(FakeStudentsRepository.akshita) != nil && store
            .message == "Couldn't delete Akshita. Check your connection and try again.")
    }

    @Test func classesAreAddedEditedAndMembersAssigned() async throws {
        let store = make()
        await store.load()
        var draft = ClassroomDraft()
        draft.name = "Class 12 Physics"
        let made = await store.addClass(draft)
        #expect(made != nil && store.activeClasses.count == 3)
        let sahil = try #require(store.students.first { $0.name == "Sahil Verma" })
        try await store.assign([sahil.id], to: #require(made?.id))
        #expect(try store.members(of: #require(made?.id)).map(\.name) == ["Sahil Verma"] && store.unassigned.isEmpty)
        draft.fee = Money(rupees: 1500)
        #expect(try await store.updateClass(#require(made?.id), with: draft))
        #expect(try store.classroom(#require(made?.id))?.monthlyFee == Money(rupees: 1500))
    }

    @Test func archivingAClassDetachesItsMembers() async {
        let store = make()
        await store.load()
        await store.archiveClass(FakeClassesRepository.science.id)
        #expect(store.classroom(FakeClassesRepository.science.id)?.isArchived == true && store.activeClasses.count == 1)
        #expect(store.unassigned.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das", "Sahil Verma"])
        #expect(store.students.first { $0.name == "Dev Kumar" }?.monthlyFee == Money(rupees: 1000), "an own fee stays")
        #expect(classes.archived == [FakeClassesRepository.science.id])
    }

    @Test func writesUpdateTheCache() async {
        let cache = tempCache()
        let store = make(cache: cache)
        await store.load()
        await store.setArchived(FakeStudentsRepository.akshita, true)
        #expect(cache.load()?.students.first { $0.id == FakeStudentsRepository.akshita }?.isArchived == true)
    }

    @Test func loadIfNeededReadsOnlyTheFirstTime() async {
        let store = make()
        await store.loadIfNeeded()
        #expect(store.students.count == 10)
        students.students = []
        await store.loadIfNeeded()
        #expect(store.students.count == 10, "a screen pushed over the list does not read again")
    }

    @Test func removingAMemberLeavesThemWithNoClass() async throws {
        let store = make()
        await store.load()
        let dev = try #require(store.students.first { $0.name == "Dev Kumar" })
        await store.assign([dev.id], to: nil)
        #expect(store.student(dev.id)?.classID == nil && store.members(of: FakeClassesRepository.science.id).count == 2)
        #expect(students.assigned.last?.1 == nil && store.student(dev.id)?.monthlyFee == Money(rupees: 1000))
    }
}
