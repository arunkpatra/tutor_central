import Domain
import Foundation
import Testing
@testable import Data

/// A `marks` row from a marked mock (migration 0021): the questions as the API's CheckOutput writes them.
struct MarkRowTests {
    static let rows = Data("""
    [{"id":"99999999-9999-9999-9999-999999999991","student_id":"55555555-5555-5555-5555-55555555555d",\
    "subject":"Science","test":"Science unit test 3 · mock","date":"2026-10-14","score":14.00,"max":25,\
    "photo_path":null,"school_item_id":"66666666-6666-6666-6666-666666666661",\
    "artefact_id":"77777777-7777-7777-7777-777777777779",\
    "questions":[{"number":1,"text":"Spot the change","note":"Correct","marks":1,"of":1}]},
    {"id":"99999999-9999-9999-9999-999999999992","student_id":"55555555-5555-5555-5555-55555555555d",\
    "subject":"Mathematics","test":"Unit test 2","date":"2026-10-02","score":14,"max":25.0,"photo_path":null,\
    "school_item_id":null,"artefact_id":null,"questions":null}]
    """.utf8)

    @Test func aRowReadsItsQuestionsAndLinks() throws {
        let marks = try SupabaseRecordRepository.decoder.decode([MarkRow].self, from: Self.rows).compactMap(\.record)
        #expect(marks.count == 2)
        #expect(marks[0].score == 14 && marks[0].max == 25 && marks[0].line == "14 of 25")
        #expect(marks[0].questions?.first?.marks == 1 && marks[0].questions?.first?.note == "Correct")
        #expect(marks[0].schoolItemID != nil && marks[0].artefactID != nil && marks[0].date.day == 14)
        #expect(marks[1].questions == nil && marks[1].schoolItemID == nil)
    }
}

@MainActor struct FakeRecordMarksTests {
    let centre = FakeSchoolsRepository.centre
    let student = UUID()

    @Test func marksComeNewestFirstAndAMarkIsAddedAndUndone() async throws {
        let repo = FakeRecordRepository()
        let older = try await repo.addMark(
            NewMark(
                studentID: student,
                subject: "Science",
                test: "Unit test 1",
                date: #require(Day(year: 2026, month: 9, day: 1)),
                score: 19,
                max: 25
            ),
            centre: centre
        )
        let newer = try await repo.addMark(
            NewMark(
                studentID: student,
                subject: "Science",
                test: "Mock",
                date: #require(Day(year: 2026, month: 10, day: 14)),
                score: 14,
                max: 25
            ),
            centre: centre
        )
        #expect(try await repo.marks(centre: centre, students: [student]).map(\.id) == [newer.id, older.id])
        #expect(try await repo.marks(centre: centre, students: [UUID()]).isEmpty)
        try await repo.deleteMark(id: newer.id, centre: centre)
        #expect(try await repo.marks(centre: centre, students: [student]).map(\.id) == [older.id])
    }
}

@MainActor struct FakeMessageLogSchoolTests {
    let centre = FakeSchoolsRepository.centre

    @Test func tomorrowAndTheForwardAskAreLoggedAndRead() async throws {
        let (dev, meher) = (UUID(), UUID())
        let repo = FakeMessageLogRepository()
        _ = try await repo.logTestTomorrow(centre: centre, studentID: dev, language: .hindi, body: "नमस्ते")
        _ = try await repo.logForwardAsk(centre: centre, studentID: dev)
        let asked = try await repo.logForwardAsk(centre: centre, studentID: meher)
        #expect(try await repo.forwardAsked(centre: centre) == [dev: FakeCountsRepository.fixedNow, meher: asked])
        let since = FakeCountsRepository.fixedNow.addingTimeInterval(-60)
        let entries = try await repo.entries(centre: centre, since: since)
        #expect(entries.filter { $0.studentID == dev }.map(\.entry.kind).sorted { $0.rawValue < $1.rawValue }
            == [.forwardAsk, .testTomorrow])
        #expect(try await repo.messages(centre: centre, student: dev).first { $0.kind == .testTomorrow }?
            .language == .hindi)
        #expect(try await repo.entries(centre: centre, since: FakeCountsRepository.fixedNow.addingTimeInterval(60))
            .isEmpty)
    }
}

@MainActor struct FakePhotoStoreRemoveTests {
    @Test func aPhotoIsRemovedByItsPath() async throws {
        let store = FakePhotoStore()
        let centre = UUID()
        let path = try await store.add(Data([0xFF, 0xD8]), centre: centre, kind: "item")
        let other = try await store.add(Data([0xFF, 0xD8]), centre: centre, kind: "item")
        try await store.remove(path: path)
        #expect(store.paths == [other])
    }
}

@MainActor struct FakePlansSchoolTests {
    let centre = UUID()
    let exam = UUID()
    let student = UUID()

    func mock() -> NewArtefact {
        NewArtefact(
            kind: .mock, source: .made, title: "Science unit test 3",
            content: .mock(MockContent(
                title: "Science unit test 3", durationMinutes: 40, sections: [],
                pattern: MockPattern(marks: 25, durationMinutes: 40), portions: [], schoolItemID: exam
            )),
            photoPath: nil, generationID: UUID(), regeneratedFrom: nil
        )
    }

    @Test func keepWithAnItemAndNoPlanLinksNoLine() async throws {
        let repo = FakePlansRepository()
        let made = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        let kept = try await repo.keep(mock(), to: ArtefactLink(item: exam, student: nil), centre: centre)
        #expect(kept.schoolItemID == exam && kept.planID == nil && kept.generationID != nil)
        let read = try #require(try await repo.plan(id: made.id, centre: centre))
        #expect(!read.items.contains { $0.artefactID == kept.id })
        #expect(try await repo.mock(for: exam, centre: centre)?.id == kept.id)
        #expect(try await repo.mock(for: UUID(), centre: centre) == nil)
    }

    @Test func aGapReportIsFoundByItsExamAndStudentAndItsContentIsSet() async throws {
        let repo = FakePlansRepository()
        let content = GapReportContent(
            summary: "x", bySkill: [], days: [GapReportContent.DayPlan(title: "Wed", line: "Balancing")], usedAt: nil,
            score: 14, max: 25, schoolItemID: exam
        )
        let report = NewArtefact(
            kind: .gapReport, source: .made, title: "After the mock", content: .gapReport(content), photoPath: nil,
            generationID: nil, regeneratedFrom: nil
        )
        let kept = try await repo.keep(report, to: ArtefactLink(item: exam, student: student), centre: centre)
        #expect(try await repo.gapReport(for: exam, student: student, centre: centre)?.id == kept.id)
        #expect(try await repo.gapReport(for: exam, student: UUID(), centre: centre) == nil)
        var used = content
        used.usedAt = FakeCountsRepository.fixedNow
        try await repo.setContent(.gapReport(used), artefact: kept.id, centre: centre)
        #expect(try await repo.artefact(id: kept.id, centre: centre)?.content == .gapReport(used))
        #expect(try await repo.artefacts(for: exam, centre: centre).map(\.id) == [kept.id])
    }

    @Test func nameGroupRenamesTheGroupAndItsTeachLines() async throws {
        let repo = FakePlansRepository()
        let made = try await repo.make(PlanSamples.unnamedDraft, centre: centre)
        let sheet = try await repo.keep(
            NewArtefact(
                kind: .sheet, source: .made, title: "s",
                content: .sheet(SheetContent(
                    title: "s",
                    instructions: nil,
                    questions: [],
                    forHomework: true,
                    light: false
                )),
                photoPath: nil, generationID: nil, regeneratedFrom: nil
            ),
            to: ArtefactLink(plan: made.id, group: 1, student: nil, itemKind: .homework), centre: centre
        )
        try await repo.nameGroup(
            plan: made.id,
            group: 1,
            chapter: "Chemical reactions",
            skill: "Balance an equation",
            centre: centre
        )
        let read = try #require(try await repo.plan(id: made.id, centre: centre))
        #expect(read.groups.first { $0.number == 1 }?.skill == "Balance an equation")
        #expect(read.groups.first { $0.number == 1 }?.chapter == "Chemical reactions")
        #expect(read.items.filter { $0.groupNo == 1 && $0.kind == .teach }
            .allSatisfy { $0.words == "Teach: Balance an equation" })
        #expect(read.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy { $0.artefactID == sheet.id })
    }
}
