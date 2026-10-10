import Data
import Domain
import Foundation
import Testing
@testable import Students

/// The student's page V2 (P10-Student, -Record, -End, -NotKnown, -Ladder): the header, tracking, this week, the record,
/// the checks, homework, school and messages.
@MainActor struct StudentDetailV2Tests {
    let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()

    func register() async -> RegisterStore {
        let store = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }, schools: FakeSchoolsRepository()
        )
        await store.load()
        return store
    }

    func detail(
        _ id: UUID, record: FakeRecordRepository = FakeRecordRepository(),
        textbooks: FakeTextbooksRepository = .seeded(), messages: FakeMessageLogRepository? = nil
    ) async -> StudentDetailStore {
        let store = await StudentDetailStore(
            id: id, register: register(),
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
            messages: messages ?? FakeMessageLogRepository(logs: FakeMessageLogRepository.seed),
            textbooks: textbooks, record: record, now: { [now] in now }
        )
        await store.load()
        return store
    }

    @Test func hemanthsHeaderAndTrackingCard() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        #expect(store.classChip == "Class 10" && store.batchChip == "Class 10 Maths")
        #expect(store.schoolLine == "Vidya Niketan · CBSE")
        #expect(store.tracking?.status == .watch && store.tracking?.since == "since Fri 2 Oct")
        #expect(store.tracking?.reasons == "5 of 9 checks right over three weeks. Absent 2 times in four weeks.")
        #expect(store.tracking?.next.hasPrefix("Teach ") == true && store.tracking?.placeAction == false)
    }

    @Test func theRecordListsTheBooksChaptersWithTheirStates() async throws {
        let store = await detail(FakeStudentsRepository.hemanth)
        let maths = try #require(store.subjects.first { $0.title == "Mathematics" })
        #expect(maths.line == "14 chapters from the book · 3 taught")
        #expect(maths.chapters[0].line == "4 of 4 secure" && maths.chapters[3].line == "Not started")
        #expect(maths.chapters[1].line == "2 of 3 secure · 1 practising")
        #expect(maths.chapters[2].line == "1 secure · 1 taught · 1 revisit · 1 to come")
        store.openChapter(maths.chapters[1].id)
        let opened = try #require(store.subjects.first { $0.title == "Mathematics" })
        #expect(opened.chapters[1].open && opened.chapters[1].skills.count == 3)
        #expect(opened.chapters[1].skills[2].mark == .practising)
    }

    @Test func riyaIsNotKnownYetAndHerBatchsSubjectWaitsForItsBook() async {
        let store = await detail(FakeStudentsRepository.riya)
        #expect(store.tracking?.status == .notKnown && store.tracking?.placeAction == false)
        #expect(store.tracking?.reasons
            == "Riya joined on Mon 5 Oct. Her first week's checks show where she stands; a placement shows it sooner.")
        #expect(store.tracking?.next == "Start with the class's first chapter until the checks say otherwise.")
        #expect(store.subjects.map(\.title) == ["Mathematics"] && store.subjects[0].chapters.isEmpty)
        #expect(store.subjects[0].line == "Nothing from a book yet")
        let empty = "Photograph the contents page of Riya's mathematics book. Everyone at Vidya Niketan in class 5 "
        #expect(store.subjects[0].emptyLine == empty + "gets the same chapters.")
        #expect(store.missingBookLine == nil && store.checks == nil)
        #expect(store.schoolLine == "Vidya Niketan")
    }

    @Test func aV1StudentWithoutAClassIsToldWhatToSet() async throws {
        let register = await register()
        let bir = try #require(register.students.first { $0.name == "Bir Bikram Singh" })
        let store = await detail(bir.id)
        #expect(store.classChip == nil && store.schoolLine == nil)
        #expect(store.missingBookLine == "Set Bir's class and school from Edit to add a book.")
    }

    @Test func sahilsLadder() async throws {
        let store = await detail(FakeStudentsRepository.sahil)
        let reading = try #require(store.subjects.first { $0.title == "Reading" })
        #expect(reading.ladder?.steps.prefix(2).allSatisfy { $0.step == .secure } == true)
        #expect(reading.ladder?.line == "Sentences · moved up Mon 28 Sep")
        #expect(Array(store.subjects.prefix(3).map(\.title)) == ["Reading", "Writing", "Numbers"])
    }

    @Test func theChecksTrendAndHomeworkRows() async throws {
        let store = await detail(FakeStudentsRepository.hemanth)
        let checks = try #require(store.checks)
        #expect(!checks.right.isEmpty && checks.right.allSatisfy { (0 ... 3).contains($0) })
        #expect(checks.percent.hasSuffix("%") && checks.line.contains("right · 3 questions a class"))
        #expect(store.homework.first?.status == .given && store.homework.first?.line.hasPrefix("Given ") == true)
        let first = try #require(store.homework.first)
        await store.setHomework(first.id, .notDone)
        #expect(store.homework.first?.status == .notDone)
    }

    @Test func theMessagesSectionNamesKindAndDay() async throws {
        let store = await detail(FakeStudentsRepository.hemanth)
        let first = try #require(store.messages.first)
        #expect(first.title == "Absence alert" && first.line == "Mon 5 Oct")
        #expect(store.schoolEmptyLine == "Nothing from Hemanth's school yet")
    }

    @Test func thisWeekHasTheSessionsHeWasIn() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        #expect(store.thisWeek.allSatisfy { $0.title == "Absent" || $0.title.hasPrefix("Came") })
        #expect(store.thisWeek.first?.day == "Mon")
    }
}
