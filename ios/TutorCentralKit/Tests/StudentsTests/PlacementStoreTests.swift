import Data
import Domain
import Foundation
import Testing
@testable import Students

@MainActor struct PlacementStoreTests {
    let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()

    func store(
        _ id: UUID = FakeStudentsRepository.riya, ai: FakeAIRepository = FakeAIRepository(),
        record: FakeRecordRepository = FakeRecordRepository(), textbooks: FakeTextbooksRepository? = nil
    ) async throws -> (PlacementStore, RegisterStore) {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let books: FakeTextbooksRepository = if let textbooks {
            textbooks
        } else {
            try await FakeTextbooksRepository.seededWithRiyasMaths()
        }
        let store = PlacementStore(
            studentID: id, register: register, ai: ai, textbooks: books, record: record,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), now: { [now] in now },
            online: { true }
        )
        await store.load()
        return (store, register)
    }

    @Test func oneRowPerChapterInTheBooksOrderWithTheChaptersFirstSkill() async throws {
        let ai = FakeAIRepository()
        let (store, _) = try await store(ai: ai)
        #expect(store.subjects.count == 1 && store.subjects[0].rows.count == 5)
        let chapters = ["The Fish Tale", "Shapes and Angles", "How Many Squares?", "Parts and Wholes"]
        #expect(ai.placementCalls == [chapters + ["Does it Look the Same?"]])
        #expect(store.subjects[0].rows[0].skill == "Compare lengths and weights")
        #expect(store.subjects[0].countLine == "0 of 5 right" && !store.canFinish)
        #expect(store.title == "Placement · Riya")
    }

    @Test func doneKeepsTheTapsAndStartsTheChaptersFromTheFirstWrong() async throws {
        let record = FakeRecordRepository()
        let books = try await FakeTextbooksRepository.seededWithRiyasMaths()
        let (store, register) = try await store(record: record, textbooks: books)
        store.subjects[0].rows[0].tap = true
        store.subjects[0].rows[1].tap = true
        store.subjects[0].rows[2].tap = false
        store.subjects[0].rows[4].tap = true
        #expect(store.subjects[0].countLine == "3 of 5 right" && store.canFinish)
        #expect(await store.finish())
        let placement = try #require(record.placements.first)
        #expect(placement.checks.count == 4 && placement.checks.allSatisfy(\.isPlacement))
        let chapters = try await books.chapters(student: FakeStudentsRepository.riya)
        let skills = try await books.skills(student: FakeStudentsRepository.riya)
        let firstTwo = Set(chapters.filter { $0.position <= 2 }.map(\.id))
        #expect(Set(placement.states.map(\.skillID)) ==
            Set(skills.filter { firstTwo.contains($0.chapterID) }.map(\.id)))
        #expect(placement.track?.status == .onTrack)
        #expect(register.student(FakeStudentsRepository.riya)?.trackStatus == .onTrack)
    }

    @Test func aLadderStudentIsPlacedOnStepsAndChapters() async throws {
        let ai = FakeAIRepository()
        let (store, _) = try await store(FakeStudentsRepository.sahil, ai: ai, textbooks: .seeded())
        #expect(store.subjects.map(\.title) == ["Reading", "Writing", "Numbers"])
        #expect(ai.placementCalls.contains(["Letters", "Words", "Sentences", "Paragraph", "Story"]))
        #expect(store.subjects[0].rows[2].skill == "Sentences")
    }

    @Test func aFailedSubjectSaysSoInPlaceAndTheOthersStand() async throws {
        let ai = FakeAIRepository()
        ai.scriptBySubject = ["Writing": .failure(.service)]
        let (store, _) = try await store(FakeStudentsRepository.sahil, ai: ai, textbooks: .seeded())
        #expect(store.subjects[1].failure == "The AI service didn't answer. Try again.")
        #expect(store.subjects[0].rows.count == 5)
        ai.scriptBySubject = [:]
        await store.retry(store.subjects[1].id)
        #expect(store.subjects[1].failure == nil && store.subjects[1].rows.count == 5)
    }
}
