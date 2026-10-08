import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct StudentDetailStoreTests {
    func register() async -> RegisterStore {
        let store = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func theLinesOfTheBoard() async {
        let detail = await StudentDetailStore(id: FakeStudentsRepository.akshita, register: register())
        #expect(detail.student?.name == "Akshita Rao" && detail.classroom?.name == "Class 10 Maths")
        #expect(detail.feeLine == "₹1,200 a month, the class fee" && detail.monthTitle == "October 2026")
        #expect(detail.monthLine == "Paid by UPI on 4 Oct" && detail.monthAmount == "₹1,200" && detail.monthMark?
            .text == "Paid")
        #expect(detail.archivedLine == nil && detail.notesLine == nil)
        #expect(detail.callURL?.absoluteString == "tel:+919799113211" && detail.whatsAppURL?
            .absoluteString == "https://wa.me/919799113211")
    }

    @Test func ownFeeDueAndNoInvoiceReadRight() async throws {
        let register = await register()
        let riya = try #require(register.students.first { $0.name == "Riya Sharma" })
        #expect(StudentDetailStore(id: riya.id, register: register).feeLine == "₹1,500 a month")
        let dev = try #require(register.students.first { $0.name == "Dev Kumar" })
        let devDetail = StudentDetailStore(id: dev.id, register: register)
        #expect(devDetail.monthLine == "Due" && devDetail.monthMark?.text == "Due")
        var draft = StudentDraft(dev)
        draft.fee = nil
        draft.classID = nil
        _ = await register.updateStudent(dev.id, with: draft)
        #expect(StudentDetailStore(id: dev.id, register: register).feeLine == "No fee set yet")
    }

    @Test func archiveRestoreAndDeleteGoThroughTheRegister() async {
        let register = await register()
        let detail = StudentDetailStore(id: FakeStudentsRepository.akshita, register: register)
        await detail.archive()
        #expect(detail.student?.isArchived == true && detail.archivedChip == "Archived 7 Oct" && detail
            .archivedLine != nil)
        await detail.restore()
        #expect(detail.student?.isArchived == false && detail.archivedChip == nil)
        #expect(await detail.delete())
        #expect(detail.student == nil && register.student(FakeStudentsRepository.akshita) == nil)
    }

    @Test func aLinkToAMissingStudentSaysSo() async {
        let detail = await StudentDetailStore(id: UUID(), register: register())
        #expect(detail.student == nil && StudentDetailStore.missingMessage == "That student is no longer here.")
    }
}
