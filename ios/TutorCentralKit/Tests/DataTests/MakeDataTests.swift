import Domain
import Foundation
import Testing
@testable import Data

/// Make's reads and writes (plan/phase-15-plan.md Task 6): `made_from` and `made_for` on a row, Make's keep, the list
/// of what Make made, the note's own words.
struct MakeDataTests {
    let made = MakeFor(target: .classLevel(.eight), title: "Class 8", line: "Science · Balancing equations")

    var sheet: NewArtefact {
        NewArtefact(
            kind: .sheet, source: .made, title: "Balancing equations · sheet",
            content: .sheet(SheetContent(
                title: "B",
                instructions: nil,
                questions: [],
                forHomework: false,
                light: false
            )),
            photoPath: nil, generationID: nil, regeneratedFrom: nil
        )
    }

    @Test func aRowWithMadeFromAndMadeForDecodes() throws {
        let json = #"""
        {"id":"7a1f0000-0000-0000-0000-000000000005","kind":"sheet","source":"made",
         "title":"Balancing equations · sheet","content":{"title":"B","instructions":null,"questions":[],
         "for_homework":false,"light":false,
         "made_for":{"target":{"kind":"class","level":"8"},"title":"Class 8","line":"Science · Balancing equations"}},
         "photo_path":null,"student_id":null,"plan_id":null,"regenerated_from":null,
         "created_at":"2026-10-07T11:06:00+00:00","generation_id":null,"school_item_id":null,"made_from":"make"}
        """#
        let artefact = try #require(try PostgRESTDecoder.make().decode(ArtefactRow.self, from: Data(json.utf8))
            .artefact)
        #expect(artefact.madeFrom == "make" && artefact.isMade)
        #expect(artefact.madeFor == made)
        if case .sheet = artefact.content {} else {
            Issue.record("not a sheet")
        }
    }

    @Test func makesKeepCarriesMadeFromAndTheTargetInTheContent() throws {
        let params = try SupabasePlansRepository.keepParams(
            sheet.made(for: made), to: ArtefactLink(plan: nil, group: 0, student: nil, itemKind: .practise),
            centre: UUID()
        )
        #expect(params["p_made_from"] == .string("make"))
        guard case let .object(row) = params["p_artefact"], case let .object(content) = row["content"]
        else { Issue.record("no content"); return }
        #expect(content["made_for"] != nil)
    }

    @Test func thePlansKeepSendsNoMadeFrom() throws {
        let params = try SupabasePlansRepository.keepParams(
            sheet, to: ArtefactLink(plan: UUID(), group: 1, student: nil, itemKind: .practise), centre: UUID()
        )
        #expect(params["p_made_from"] == nil)
    }

    @MainActor @Test func keepMadeIsListedByMadeNewestFirst() async throws {
        let plans = FakePlansRepository()
        let centre = UUID()
        _ = try await plans.keep(
            sheet,
            to: ArtefactLink(plan: UUID(), group: 1, student: nil, itemKind: .practise),
            centre: centre
        )
        let first = try await plans.keepMade(sheet.made(for: made), student: nil, exam: nil, centre: centre)
        plans.now = plans.now.addingTimeInterval(60)
        let second = try await plans.keepMade(
            sheet.made(for: made),
            student: FakeStudentsRepository.dev,
            exam: nil,
            centre: centre
        )
        let list = try await plans.made(centre: centre)
        #expect(list.map(\.id) == [second.id, first.id])
        #expect(second.studentID == FakeStudentsRepository.dev && second.madeFrom == "make" && second.madeFor == made)
    }

    @MainActor @Test func aRegenerateReplacesItsPredecessorInMade() async throws {
        let plans = FakePlansRepository()
        let centre = UUID()
        let first = try await plans.keepMade(sheet.made(for: made), student: nil, exam: nil, centre: centre)
        plans.now = plans.now.addingTimeInterval(60)
        let again = NewArtefact(
            kind: .sheet, source: .made, title: first.title, content: first.content, photoPath: nil, generationID: nil,
            regeneratedFrom: first.id
        )
        let second = try await plans.keepMade(again.made(for: made), student: nil, exam: nil, centre: centre)
        #expect(try await plans.made(centre: centre).map(\.id) == [second.id])
        #expect(plans.artefacts.count == 2)
    }

    @Test func aNoteBodyCarriesTutorSaysOnlyWhenGiven() throws {
        let plain = ParentsRequests.note()
        let without = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeNoteBody(
            plain,
            centre: UUID()
        ))) as? [String: Any]
        #expect(without?["tutorSays"] == nil)
        let words = plain.saying("Ask him to read aloud.")
        let with = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeNoteBody(
            words,
            centre: UUID()
        ))) as? [String: Any]
        #expect(with?["tutorSays"] as? String == "Ask him to read aloud.")
        #expect(plain.saying("   ").tutorSays == nil)
        #expect(plain.saying(String(repeating: "म", count: 320)).tutorSays?.unicodeScalars.count == 300)
    }
}

struct ProgressReaderTests {
    let october = Period(year: 2026, month: 10)

    @MainActor @Test func readsEveryStudentsSkillsChecksAndSessionsTogether() async throws {
        let textbooks = FakeTextbooksRepository.seeded()
        let record = FakeRecordRepository()
        let attendance = FakeAttendanceRepository()
        let students = FakeStudentsRepository.seed.filter { $0.archivedAt == nil }
        let reader = ProgressReader(textbooks: textbooks, record: record, attendance: attendance)
        let inputs = try await reader.read(
            students,
            span: .term(Term(schoolYear: 2026, number: 1, calendar: .standard)),
            centre: UUID(),
            calendar: DayHeading.india
        )
        #expect(Set(inputs.keys) == Set(students.map(\.id)))
        #expect(textbooks.bookReads == 1)
        #expect(record.checkReads == 1)
        #expect(attendance.monthsRead == [6, 7, 8, 9].map { Period(year: 2026, month: $0) })
        let hemanth = try #require(inputs[FakeStudentsRepository.hemanth])
        #expect(!hemanth.chapters.isEmpty && hemanth.checks
            .allSatisfy { $0.studentID == FakeStudentsRepository.hemanth })
    }

    @MainActor @Test func aFailedSkillsReadThrows() async {
        let textbooks = FakeTextbooksRepository.seeded()
        textbooks.nextError = URLError(.notConnectedToInternet)
        let reader = ProgressReader(
            textbooks: textbooks,
            record: FakeRecordRepository(),
            attendance: FakeAttendanceRepository()
        )
        await #expect(throws: URLError.self) {
            _ = try await reader.read(
                FakeStudentsRepository.seed,
                span: .month(october),
                centre: UUID(),
                calendar: DayHeading.india
            )
        }
    }
}
