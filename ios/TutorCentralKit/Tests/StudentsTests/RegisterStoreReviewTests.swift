import Data
import Domain
import Foundation
import Testing
@testable import Students

/// The final review of Phase 3: writes that overlap, as they do on a slow network; a first read that fails.
@MainActor struct RegisterStoreReviewTests {
    let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
    let classes = FakeClassesRepository(classes: FakeClassesRepository.seed)

    func make() -> RegisterStore {
        RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: students, classes: classes, cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
    }

    /// Review, Important: a failing write rolls back only its own rows, never another write that succeeded meanwhile.
    @Test func aFailedMoveDoesNotUndoAClassArchivedMeanwhile() async throws {
        let store = make()
        await store.load()
        let sahil = try #require(store.students.first { $0.name == "Sahil Verma" })
        students.delay = .milliseconds(150)
        students.nextError = URLError(.badServerResponse)
        let move = Task { await store.assign([sahil.id], to: FakeClassesRepository.maths.id) }
        try await Task.sleep(for: .milliseconds(30))
        await store.archiveClass(FakeClassesRepository.science.id)
        await move.value
        #expect(store.student(sahil.id)?.classID == nil, "the failed move is undone")
        #expect(store.members(of: FakeClassesRepository.science.id).isEmpty, "the archive that succeeded stays")
    }

    /// Review, Important: an edit lands on its own class even when the list re-sorted while it was saving.
    @Test func aClassEditLandsOnItsClassAfterTheListChanged() async throws {
        let store = make()
        await store.load()
        var draft = ClassroomDraft(FakeClassesRepository.science)
        draft.fee = Money(rupees: 1100)
        classes.delay = .milliseconds(150)
        let edit = Task { await store.updateClass(FakeClassesRepository.science.id, with: draft) }
        try await Task.sleep(for: .milliseconds(30))
        classes.delay = nil
        var art = ClassroomDraft()
        art.name = "Class 1 Art"
        await store.addClass(art)
        #expect(await edit.value)
        #expect(store.classroom(FakeClassesRepository.science.id)?.monthlyFee == Money(rupees: 1100))
        #expect(store.classes.first { $0.name == "Class 1 Art" }?.monthlyFee == nil)
        #expect(
            store.classroom(FakeClassesRepository.maths.id)?.name == "Class 10 Maths",
            "no other class is overwritten"
        )
    }

    /// Review, Important: with nothing cached and the first read failed, the register is not "empty": it is unread.
    @Test func aFailedFirstReadIsNotAnEmptyRegister() async {
        students.nextError = URLError(.badServerResponse)
        let store = make()
        await store.load()
        #expect(store.students.isEmpty && store.error != nil && !store.showsEmptyRegister)
        await store.refresh()
        #expect(store.students.count == 10 && !store.showsEmptyRegister)
        let empty = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(),
            classes: FakeClassesRepository(), cache: nil, now: { FakeCountsRepository.fixedNow }
        )
        await empty.load()
        #expect(empty.showsEmptyRegister)
    }
}
