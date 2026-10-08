import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answers on 2026-10-08: an insert's row, a failed scan's row, and the history read.
struct GenerationRowTests {
    static let inserted = Data("""
    [{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","centre_id":"22222222-2222-2222-2222-222222222222","kind":"paper",\
    "input":{"kind": "paper", "level": "medium", "marks": 20, "topic": "Quadratic equations", \
    "subject": "Mathematics", "questions": 10, "classLevel": "Class 10 Maths"},\
    "output":"{\\"title\\":\\"Quadratic equations\\",\\"sections\\":[]}",\
    "model":"claude-sonnet-5-5","tokens_in":812,"tokens_out":1460,"status":"ok",\
    "created_at":"2026-10-08T18:09:01.372972+00:00","updated_at":"2026-10-08T18:09:01.372972+00:00"}]
    """.utf8)
    static let failedScan = Data("""
    [{"id":"86c64b2d-486a-434f-8243-9c0cabe22a3c","centre_id":"22222222-2222-2222-2222-222222222222",\
    "kind":"scan_register","input":{"kind": "scan_register", "bytes": 412330, "pages": 1},"output":null,\
    "model":"claude-opus-5-5","tokens_in":null,"tokens_out":null,"status":"failed",\
    "created_at":"2026-10-08T18:09:01.387448+00:00","updated_at":"2026-10-08T18:09:01.387448+00:00"}]
    """.utf8)
    static let history = Data("""
    [{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","kind":"paper","input":{"kind": "paper", "level": "medium", \
    "marks": 20, "topic": "Quadratic equations", "subject": "Mathematics", "questions": 10, \
    "classLevel": "Class 10 Maths"},"output":"{\\"title\\":\\"Quadratic equations\\",\\"sections\\":[]}",\
    "model":"claude-sonnet-5-5","tokens_in":812,"tokens_out":1460,"status":"ok",\
    "created_at":"2026-10-08T18:09:01.372972+00:00"}]
    """.utf8)
    static let sections = #"\"sections\":[{\"title\":\"A\",\"marksEach\":1,"#
        + #"\"questions\":[{\"number\":1,\"text\":\"q\",\"marks\":1,\"answer\":\"a\"}]}]"#

    @Test func decodesARowIntoAGenerationWhenItsOutputParses() throws {
        let rows = try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Self.history)
        let row = try #require(rows.first)
        #expect(row.kind == "paper" && row.createdAt.timeIntervalSince1970 > 1_790_000_000)
        // An empty sections array fails PaperOutput on the API, so the app treats this stored output as no paper.
        #expect(row.generation == nil, "sections must not be empty")
        let okRow = try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Self.inserted)
        #expect(okRow.first?.id == UUID(uuidString: "fbc6ae19-2769-4934-bf10-c830207fd6a3"))
        let failed = try #require(try SupabaseAIHistoryRepository.decoder.decode(
            [GenerationRow].self,
            from: Self.failedScan
        )
        .first)
        #expect(failed.generation == nil && failed.output == nil)
    }

    @Test func aStoredInputComesBackAsTheRequestWhenItsKindMatches() throws {
        let withSections = (String(bytes: Self.inserted, encoding: .utf8) ?? "")
            .replacingOccurrences(of: #"\"sections\":[]"#, with: Self.sections)
        let row = try #require(try SupabaseAIHistoryRepository.decoder.decode(
            [GenerationRow].self, from: Data(withSections.utf8)
        ).first)
        let generation = try #require(row.generation)
        #expect(generation.kind == .paper)
        guard case let .paper(form)? = generation.request else {
            Issue.record("no form")
            return
        }
        #expect(form.topic == "Quadratic equations" && form.marks == 20 && form.level == .medium)
        #expect(form.subject == "Mathematics")
        #expect(form.classID == nil, "this row was written before the input carried the class's id")
    }

    @Test func theClassAndTheStudentComeBackFromTheirIDs() throws {
        let maths = "33333333-3333-3333-3333-333333333331"
        let hemanth = "aaaaaaaa-0000-0000-0000-000000000005"
        let json = """
        [{"id":"11111111-1111-1111-1111-111111111111","kind":"progress_note","input":{"kind":"progress_note",\
        "studentId":"\(hemanth)","studentName":"Hemanth Reddy","observations":"Improving","tone":"plain",\
        "subject":"Mathematics","classLevel":"Class 10 Maths"},"output":"{\\"note\\":\\"Hello Lakshmi.\\"}",\
        "created_at":"2026-10-05T10:00:00+00:00"},\
        {"id":"22222222-2222-2222-2222-222222222223","kind":"worksheet",\
        "input":{"kind":"worksheet","classId":"\(maths)",\
        "topic":"Fractions","subject":"Mathematics","classLevel":"Class 10 Maths","level":"easy","questions":12,\
        "withAnswers":false},"output":"{\\"title\\":\\"Fractions\\",\\"instructions\\":null,\
        \\"questions\\":[{\\"number\\":1,\\"text\\":\\"q\\",\\"answer\\":\\"a\\"}]}",\
        "created_at":"2026-10-05T10:00:00+00:00"}]
        """
        let rows = try SupabaseAIHistoryRepository.decoder.decode([GenerationRow].self, from: Data(json.utf8))
        let note = try #require(rows.first?.generation)
        #expect(note.studentID == UUID(uuidString: hemanth))
        guard case let .progressNote(form)? = note.request else {
            Issue.record("no note form")
            return
        }
        #expect(form.tone == .plain && form.observations == "Improving")
        let sheet = try #require(rows.last?.generation)
        guard case let .worksheet(worksheet)? = sheet.request else {
            Issue.record("no worksheet form")
            return
        }
        #expect(worksheet.classID == UUID(uuidString: maths) && !worksheet.withAnswers && worksheet.level == .easy)
    }
}
