import Data
import Domain
import Foundation
import Students
import Testing
@testable import AITools

/// Marking a mock from a photo (plan/phase-13-plan.md decisions 13 and 14): the preset's student and key, the scheme
/// step
/// skipped, Save writes the mark with the notes line, Undo takes both back; a paper's check writes a mark too.
@MainActor struct CheckPresetTests {
    nonisolated static let now = FakeCountsRepository.fixedNow
    static let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 1]), mediaType: "image/jpeg")
    static let mockID = UUID(uuidString: "abababab-0000-0000-0013-000000000001")!
    static let generation = UUID(uuidString: "abababab-0000-0000-0013-000000000002")!
    static let exam = FakeSchoolItemsRepository.devsTest

    static var preset: CheckPreset {
        CheckPreset(
            studentID: FakeStudentsRepository.dev,
            scheme: .mock(generationID: generation, artefactID: mockID),
            mark: MarkTarget(
                subject: "Science",
                test: "Science unit test · mock",
                schoolItemID: exam,
                artefactID: mockID
            )
        )
    }

    /// The seed with Dev's parent's consent recorded unless asked otherwise.
    static func students(devConsents: Bool = true) -> [Student] {
        FakeStudentsRepository.seed.map { student in
            guard student.id == FakeStudentsRepository.dev, devConsents, let phone = student.parentPhone else {
                return student
            }
            var changed = student
            changed.consent = ConsentRecord(at: now, phone: phone, how: .inPerson)
            return changed
        }
    }

    static func make(
        preset: CheckPreset? = preset, ai: FakeAIRepository = FakeAIRepository(),
        record: FakeRecordRepository = FakeRecordRepository(marks: []),
        students: FakeStudentsRepository = FakeStudentsRepository(students: students()), online: Bool = true
    ) async -> CheckStore {
        let workspace = FakeCentreRepository.meeraWorkspaceConsented
        let register = RegisterStore(
            workspace: workspace, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { now }
        )
        await register.load()
        let store = CheckStore(
            workspace: workspace, register: register, ai: ai,
            history: FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed), students: students,
            centres: FakeCentreRepository(), now: { now }, record: record, preset: preset
        )
        store.online = { online }
        return store
    }

    @Test func aPresetSkipsTheSchemeAndSendsTheStudent() async {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai)
        #expect(store.studentID == FakeStudentsRepository.dev && store.skipsScheme)
        store.addPages([Self.page])
        await store.check()
        #expect(store.stage == .result)
        #expect(ai.checks == [Self.preset.scheme] && ai.checkStudents == [FakeStudentsRepository.dev])
    }

    @Test func saveWritesTheMarkWithItsQuestionsAndTheNotesLine() async throws {
        let record = FakeRecordRepository(marks: [])
        let students = FakeStudentsRepository(students: Self.students())
        let store = await Self.make(record: record, students: students)
        store.addPages([Self.page])
        await store.check()
        let result = try #require(store.result)
        #expect(await store.save())
        let mark = try #require(record.marks.first)
        #expect(record.marks.count == 1 && mark.studentID == FakeStudentsRepository.dev)
        #expect(mark.score == result.total && mark.max == result.outOf && mark.subject == "Science")
        #expect(mark.schoolItemID == Self.exam && mark.artefactID == Self.mockID)
        #expect(mark.questions?.count == result.questions.count && mark.test == "Science unit test · mock")
        let notes = try await students.students(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            period: Period(year: 2026, month: 10)
        )
        .first { $0.id == FakeStudentsRepository.dev }?.notes
        #expect(notes?
            .hasSuffix("Science unit test · mock · \(result.total) of \(result.outOf) · \(result.summary)") == true)
    }

    @Test func undoRemovesTheMarkAndTheNotesLine() async throws {
        let record = FakeRecordRepository(marks: [])
        let students = FakeStudentsRepository(students: Self.students())
        let store = await Self.make(record: record, students: students)
        let before = Self.students().first { $0.id == FakeStudentsRepository.dev }?.notes
        store.addPages([Self.page])
        await store.check()
        #expect(await store.save())
        #expect(await store.undoSave())
        #expect(record.marks.isEmpty)
        let notes = try await students.students(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            period: Period(year: 2026, month: 10)
        )
        .first { $0.id == FakeStudentsRepository.dev }?.notes
        #expect(notes == before)
    }

    @Test func aPaperSchemeWritesAMarkWithThePapersSubjectAndATypedSchemeDoesNot() async throws {
        let record = FakeRecordRepository(marks: [])
        let store = await Self.make(preset: nil, record: record)
        store.studentID = FakeStudentsRepository.dev
        store.addPages([Self.page])
        await store.loadPapers()
        let paper = try #require(store.papers.first {
            if case .paper = $0.result {
                true
            } else {
                false
            }
        })
        store.scheme = .paper(generationID: paper.id)
        await store.check()
        #expect(await store.save())
        #expect(record.marks.first?.test == paper.title(studentName: { _ in nil }))
        #expect(record.marks.first?.subject.isEmpty == false && record.marks.first?.artefactID == nil)
        let typed = FakeRecordRepository(marks: [])
        let other = await Self.make(preset: nil, record: typed)
        other.studentID = FakeStudentsRepository.dev
        other.addPages([Self.page])
        other.scheme = .typed("Q1 (1) b")
        await other.check()
        #expect(await other.save())
        #expect(typed.marks.isEmpty)
    }

    @Test func aStudentWithoutConsentIsRefusedInWordsBeforeAnyCall() async {
        let ai = FakeAIRepository()
        let store = await Self.make(
            ai: ai, students: FakeStudentsRepository(students: Self.students(devConsents: false))
        )
        store.addPages([Self.page])
        await store.check()
        #expect(ai.checks.isEmpty)
        #expect(store.stage == .failed("Marking Dev's paper waits for Ramesh's consent. Record it on Dev's page."))
    }

    @Test func offlineMarkingIsRefusedAndKeepsThePages() async {
        let ai = FakeAIRepository()
        let store = await Self.make(ai: ai, online: false)
        store.addPages([Self.page, Self.page])
        await store.check()
        #expect(ai.checks.isEmpty && store.pages.count == 2)
        #expect(store.message == OfflineRefusal.words(for: .mark))
    }

    /// The pages step's Check: with a preset it starts checking (the scheme step skipped); offline it stays.
    @Test func checkFromThePagesStartsAtOnceWithAPreset() async {
        let store = await Self.make()
        store.addPages([Self.page])
        #expect(await store.checkFromPages())
        #expect(store.stage == .checking || store.stage == .result)
        let offline = await Self.make(online: false)
        offline.addPages([Self.page])
        #expect(await !offline.checkFromPages() && offline.stage == .pages)
    }

    /// Hand run 9: once a mock's marks are saved, Back leaves the whole visit; before Save, or for a check begun here,
    /// Back is one step.
    @Test func backLeavesTheVisitOnceAMocksMarksAreSaved() async {
        let store = await Self.make()
        store.addPages([Self.page])
        await store.check()
        #expect(!store.leavesVisitOnBack)
        #expect(await store.save())
        #expect(store.leavesVisitOnBack)
        let own = await Self.make(preset: nil)
        own.studentID = FakeStudentsRepository.dev
        own.addPages([Self.page])
        own.scheme = .typed("Q1 (1) b")
        await own.check()
        #expect(await own.save())
        #expect(!own.leavesVisitOnBack)
    }
}
