import Data
import Domain
import Foundation
import Students
import Testing
@testable import Make

/// What a kind's form keeps on this iPhone between visits (plan/phase-15-plan.md decision 12; the review's R-app-5),
/// and
/// that sign-out wipes it (D40).
@MainActor struct MakeRememberTests {
    nonisolated static let now = FakeCountsRepository.fixedNow

    /// The review's R-app-5: the mock and the note keep their last student as the other kinds keep their target.
    @Test func theMocksAndTheNotesStudentAreRemembered() async {
        let defaults = UserDefaults(suiteName: "make-\(UUID().uuidString)")
        let mock = await MakeFormStoreTests.kit(.mock, defaults: defaults)
        mock.store.studentID = MakeFormStoreTests.dev
        mock.store.exam = .typed(subject: "Science", title: "Unit test", portions: "Chapter 3")
        _ = await mock.store.make()
        #expect(await MakeFormStoreTests.kit(.mock, defaults: defaults).store.studentID == MakeFormStoreTests.dev)
        let note = await MakeFormStoreTests.kit(
            .noteToParent,
            students: MakeRememberTests.consenting(MakeFormStoreTests.meher),
            defaults: defaults
        )
        note.store.studentID = MakeFormStoreTests.meher
        _ = await note.store.make()
        let again = await MakeFormStoreTests.kit(
            .noteToParent,
            students: MakeRememberTests.consenting(MakeFormStoreTests.meher),
            defaults: defaults
        )
        #expect(again.store.studentID == MakeFormStoreTests.meher)
    }

    static func consenting(_ id: UUID) -> [Student] {
        FakeStudentsRepository.eveningSeed.map { student in
            guard student.id == id, let phone = student.parentPhone else { return student }
            var agreed = student
            agreed.consent = ConsentRecord(at: now, phone: phone, how: .inPerson)
            return agreed
        }
    }

    @Test func theLastTargetOfAKindIsRemembered() async {
        let defaults = UserDefaults(suiteName: "make-\(UUID().uuidString)")
        let first = await MakeFormStoreTests.kit(.sheet, defaults: defaults)
        first.store.choose(.student(MakeFormStoreTests.dev))
        _ = await first.store.make()
        let second = await MakeFormStoreTests.kit(.sheet, defaults: defaults)
        #expect(second.store.target == .student(MakeFormStoreTests.dev))
        let other = await MakeFormStoreTests.kit(.workedExample, defaults: defaults)
        #expect(other.store.target == nil)
    }

    /// D40: sign-out wipes what Make keeps on this iPhone, the last target of each kind and the brief's class.
    @Test func signOutWipesMakesRememberedChoices() {
        for kind in MakeKind.allCases {
            #expect(Wipe.defaultsKeys.contains(MakeFormStore.defaultsKey(kind)))
        }
        #expect(Wipe.defaultsKeys.contains(MakeFormStore.briefKey))
    }

    /// Hand run 5: the brief starts on the last class and subject made, as V1's forms do; Choose the first time.
    @Test func theBriefsLastClassAndSubjectAreRemembered() async {
        let defaults = UserDefaults(suiteName: "make-\(UUID().uuidString)")
        let first = await MakeFormStoreTests.kit(.brief, defaults: defaults)
        #expect(first.store.classLevel == nil)
        first.store.classLevel = .eight
        first.store.subject = "Science"
        first.store.chapter = "Chemical reactions"
        _ = await first.store.make()
        let second = await MakeFormStoreTests.kit(.brief, defaults: defaults)
        #expect(second.store.classLevel == .eight && second.store.subject == "Science")
    }
}
