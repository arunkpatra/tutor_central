import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct ScanStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let photo = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 0]), mediaType: "image/jpeg")

    static func make(
        ai: FakeAIRepository = FakeAIRepository(),
        students: FakeStudentsRepository = FakeStudentsRepository(students: FakeStudentsRepository.seed),
        centres: FakeCentreRepository = FakeCentreRepository(),
        workspace: Workspace = FakeCentreRepository.meeraWorkspaceConsented
    ) async -> ScanStore {
        let register = RegisterStore(
            workspace: workspace, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        return ScanStore(
            workspace: workspace, register: register, ai: ai, students: students, centres: centres, now: { now }
        )
    }

    @Test func readingFlagsTheRowsAgainstTheRegister() async {
        let store = await Self.make()
        await store.read(Self.photo)
        #expect(store.stage == .review && store.rows.count == 8 && store.title == "8 found")
        let dev = store.rows[2]
        #expect(dev.name == "Dev Kumar" && !dev.included)
        #expect(dev.flag == .alreadyHere(name: "Dev Kumar", className: "Class 8 Science"))
        #expect(store.rows[3].flag == .noNumber && store.rows[3].included)
        #expect(store.ticked.count == 7 && store.addLabel == "Add 7 students" && store.canAdd)
        #expect(store.classID == FakeClassesRepository.maths.id, "the first active class by default")
    }

    @Test func nothingAndAFailureHaveTheirStages() async {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai)
        ai.scanRows = []
        await store.read(Self.photo)
        #expect(store.stage == .nothing)
        ai.script = .failure(.service)
        await store.retry()
        #expect(store.stage == .failed("The AI service didn't answer. Try again.") && store.photo == Self.photo)
        ai.script = .failure(.consent)
        await store.retry()
        #expect(
            store.stage == .intro && store.needsConsent,
            "the server said no consent: back to the intro, the sheet asks"
        )
    }

    @Test func editingRemovingAndUndoingStayOnTheDevice() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        await store.read(Self.photo)
        var kavya = try #require(store.rows.first { $0.name == "Kavya Nair" })
        kavya.phone = PhoneNumber(e164: "+919876500000")
        kavya.parentName = "Asha Nair"
        store.update(kavya)
        #expect(store.rows.first { $0.id == kavya.id }?.flag == nil, "a number fixed is no longer flagged")
        store.remove(kavya.id)
        #expect(store.rows.count == 7 && store.title == "7 found" && store.addLabel == "Add 6 students")
        #expect(store.message == "Kavya Nair removed.")
        store.undoRemove()
        #expect(store.rows.count == 8 && store.rows[3].id == kavya.id, "back where it was")
        #expect(students.createdMany.isEmpty, "nothing written")
    }

    @Test func addWritesTheTickedRowsOnceAndUndoDeletesThem() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        await store.read(Self.photo)
        var added: Int?
        store.onAdded = { added = $0 }
        let count = await store.add()
        #expect(count == 7 && added == 7 && students.createdMany.count == 1 && students.createdMany[0].count == 7)
        let drafts = try #require(students.createdMany.first)
        #expect(drafts.allSatisfy { $0.classID == FakeClassesRepository.maths.id })
        #expect(drafts.first { $0.trimmedName == "Rohan Gupta" }?.fee == Money(rupees: 1500))
        #expect(drafts.first { $0.trimmedName == "Aarav Mehta" }?.fee == Money(rupees: 1200))
        #expect(!drafts.contains { $0.trimmedName == "Dev Kumar" })
        #expect(store.lastAdded.count == 7)
        #expect(await store.undoAdd(ids: store.lastAdded))
        #expect(students.deletedMany == [store.lastAdded])
        await store.read(Self.photo)
        students.nextError = URLError(.notConnectedToInternet)
        #expect(await store.add() == nil && store.message == "Couldn't add them. Check your connection and try again.")
    }

    @Test func consentIsAskedBeforeTheFirstPhotoAndRecorded() async {
        let centres = FakeCentreRepository()
        let store = await Self.make(centres: centres, workspace: FakeCentreRepository.meeraWorkspace)
        #expect(store.needsConsent)
        var merged: Workspace?
        store.onWorkspaceChanged = { merged = $0 }
        #expect(await store.recordConsent() && !store.needsConsent)
        #expect(merged?.centre.aiConsentAt != nil && centres.consents.count == 1)
    }

    @Test func noClassAddsWithoutOneAndLeavingAsksOnlyWithRows() async throws {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let store = await Self.make(students: students)
        #expect(!store.hasRows)
        await store.read(Self.photo)
        #expect(store.hasRows)
        store.classID = nil
        _ = await store.add()
        #expect(try #require(students.createdMany.first).allSatisfy { $0.classID == nil })
    }

    @Test func aRegisterNotReadYetIsReadBeforeTheRowsAreFlagged() async {
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspaceConsented, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { Self.now }
        )
        let store = ScanStore(
            workspace: FakeCentreRepository.meeraWorkspaceConsented, register: register, ai: FakeAIRepository(),
            students: students, centres: FakeCentreRepository(), now: { Self.now }
        )
        await store.read(Self.photo)
        #expect(store.rows[2].flag == .alreadyHere(name: "Dev Kumar", className: "Class 8 Science"))
        #expect(store.classID == FakeClassesRepository.maths.id)
        store.classID = nil
        await store.retry()
        #expect(store.classID == nil, "the tutor's No class stands")
    }
}
