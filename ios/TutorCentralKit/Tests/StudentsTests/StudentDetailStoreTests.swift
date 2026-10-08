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
        let detail = await StudentDetailStore(
            id: FakeStudentsRepository.akshita,
            register: register(),
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
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
        #expect(StudentDetailStore(
            id: riya.id,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
        .feeLine == "₹1,500 a month")
        let dev = try #require(register.students.first { $0.name == "Dev Kumar" })
        let devDetail = StudentDetailStore(
            id: dev.id,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
        #expect(devDetail.monthLine == "Due" && devDetail.monthMark?.text == "Due")
        var draft = StudentDraft(dev)
        draft.fee = nil
        draft.classID = nil
        _ = await register.updateStudent(dev.id, with: draft)
        #expect(StudentDetailStore(
            id: dev.id,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
        .feeLine == "No fee set yet")
    }

    @Test func archiveRestoreAndDeleteGoThroughTheRegister() async {
        let register = await register()
        let detail = StudentDetailStore(
            id: FakeStudentsRepository.akshita,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
        await detail.archive()
        #expect(detail.student?.isArchived == true && detail.archivedChip == "Archived 7 Oct" && detail
            .archivedLine != nil)
        await detail.restore()
        #expect(detail.student?.isArchived == false && detail.archivedChip == nil)
        #expect(await detail.delete())
        #expect(detail.student == nil && register.student(FakeStudentsRepository.akshita) == nil)
    }

    @Test func aLinkToAMissingStudentSaysSo() async {
        let detail = await StudentDetailStore(
            id: UUID(),
            register: register(),
            attendance: FakeAttendanceRepository(),
            messages: FakeMessageLogRepository()
        )
        #expect(detail.student == nil && StudentDetailStore.missingMessage == "That student is no longer here.")
    }

    func make(attendance: FakeAttendanceRepository) async -> StudentDetailStore {
        await StudentDetailStore(
            id: FakeStudentsRepository.akshita,
            register: register(),
            attendance: attendance,
            messages: FakeMessageLogRepository()
        )
    }

    @Test func theAttendanceSectionReadsTheMonth() async throws {
        let store = await make(attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday))
        await store.load()
        let card = try #require(store.attendanceCard)
        #expect(card.title == "October 2026" && card.percent == "100%" && card.line == "3 of 3 classes · no absences")
        let none = await make(attendance: FakeAttendanceRepository())
        await none.load()
        #expect(none.attendanceCard == nil, "nothing marked: the empty row says so")
    }

    @Test func theFeeRowReadsRemindedAndOffersActions() async throws {
        let register = await register()
        let logs = FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed)
        let hemanth = try #require(register.students.first { $0.name == "Hemanth Reddy" })
        let detail = StudentDetailStore(
            id: hemanth.id,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: logs
        )
        await detail.load()
        #expect(detail.monthLine == "Due" && detail.monthMark?.tone == .due && detail.remindedLine == nil)
        let dev = try #require(register.students.first { $0.name == "Dev Kumar" })
        let devDetail = StudentDetailStore(
            id: dev.id,
            register: register,
            attendance: FakeAttendanceRepository(),
            messages: logs
        )
        await devDetail.load()
        #expect(devDetail.monthLine == "Due · Reminded Tue 6 Oct")
        #expect(devDetail.feeAction(.remind) == .remind(studentID: dev.id, month: Period(year: 2026, month: 10)))
        #expect(devDetail.feeAction(.markPaid) == .markPaid(studentID: dev.id, month: Period(year: 2026, month: 10)))
        let akshita = StudentDetailStore(
            id: FakeStudentsRepository.akshita, register: register, attendance: FakeAttendanceRepository(),
            messages: logs
        )
        #expect(akshita.monthMark?.tone == .ok && akshita.showsFeeButtons == false)
        #expect(devDetail.showsFeeButtons)
    }
}
