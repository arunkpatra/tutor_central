import Data
import Domain
import Foundation
import Testing
@testable import Students

/// What a saved student brings with them (Phase 11): the books, the ladder, the school's board; the schools.
@MainActor struct RegisterStoreRecordTests {
    let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
    let classes = FakeClassesRepository(classes: FakeClassesRepository.seed)

    func make() -> RegisterStore {
        make(textbooks: FakeTextbooksRepository())
    }

    func make(
        textbooks: FakeTextbooksRepository,
        schools: FakeSchoolsRepository = FakeSchoolsRepository()
    ) -> RegisterStore {
        RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: students, classes: classes, cache: nil,
            now: { FakeCountsRepository.fixedNow }, schools: schools, textbooks: textbooks
        )
    }

    @Test func addingAStudentWithASchoolAndClassCopiesTheBooks() async throws {
        let textbooks = FakeTextbooksRepository(textbooks: [FakeTextbooksRepository.mathsTen])
        let store = make(textbooks: textbooks)
        await store.load()
        var draft = StudentDraft()
        draft.name = "Kavya Nair"
        draft.classLevel = .ten
        draft.schoolID = FakeSchoolsRepository.vidya.id
        let made = try #require(await store.addStudent(draft))
        #expect(textbooks.copyAllCalls == [made.id])
        var without = StudentDraft()
        without.name = "No School"
        without.classLevel = .ten
        _ = await store.addStudent(without)
        #expect(textbooks.copyAllCalls.count == 1)
    }

    @Test func aYoungStudentGetsTheLadderAtSave() async throws {
        let textbooks = FakeTextbooksRepository()
        let store = make(textbooks: textbooks)
        await store.load()
        var draft = StudentDraft()
        draft.name = "Tara"
        draft.classLevel = .ukg
        let made = try #require(await store.addStudent(draft))
        #expect(textbooks.ladderCalls == [made.id])
        var older = StudentDraft()
        older.name = "Older"
        older.classLevel = .six
        _ = await store.addStudent(older)
        #expect(textbooks.ladderCalls.count == 1)
    }

    @Test func theListSortsByStatusFirst() async {
        let store = make()
        await store.load()
        #expect(store.sort == .status)
        #expect(store.visible.first?.name == "Hemanth Reddy")
        #expect(store.visible.last?.trackStatus == .notKnown)
    }

    @Test func savingABoardOnAStudentSetsTheSchoolsWhenItHasNone() async {
        let vidya = School(id: FakeSchoolsRepository.vidya.id, name: "Vidya Niketan", board: nil)
        let schools = FakeSchoolsRepository(schools: [vidya])
        let store = make(textbooks: FakeTextbooksRepository(), schools: schools)
        await store.load()
        var draft = StudentDraft()
        draft.name = "K"
        draft.classLevel = .nine
        draft.board = .karnataka
        draft.schoolID = FakeSchoolsRepository.vidya.id
        _ = await store.addStudent(draft)
        #expect(schools.schools.first?.board == .karnataka && store.schools.first?.board == .karnataka)
    }

    @Test func aSchoolAddedFromTheFormJoinsTheListAndTheCountsAreRead() async throws {
        let store = make(textbooks: FakeTextbooksRepository())
        await store.load()
        #expect(store.schoolCounts[FakeSchoolsRepository.vidya.id] == 4)
        let made = try #require(await store.addSchool(name: "  DPS Bangalore "))
        #expect(made.name == "DPS Bangalore" && store.schools.contains(made))
    }
}
