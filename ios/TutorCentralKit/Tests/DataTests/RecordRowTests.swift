import Domain
import Foundation
import Supabase
import Testing
@testable import Data

struct RecordRowTests {
    @Test func aCheckRowAndAHomeworkRowDecode() throws {
        let check = Data(#"""
        {"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60801","student_id":"aaaaaaaa-0000-0000-0000-000000000009",
         "skill_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60751","session_id":null,"kind":"placement",
         "question":{"text":"Which is bigger, 1/2 or 1/3?"},"correct":true,"created_at":"2026-10-07T11:02:00.123+00:00"}
        """#.utf8)
        let record = try SupabaseRecordRepository.decoder.decode(CheckRow.self, from: check).record
        #expect(record.isPlacement && record.sessionID == nil && record.question == "Which is bigger, 1/2 or 1/3?")
        #expect(record.correct)
        let homework = Data(#"""
        {"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60802","student_id":"aaaaaaaa-0000-0000-0000-000000000005",
         "session_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60803","given_at":"2026-10-07T13:02:00+00:00","status":"not_done"}
        """#.utf8)
        #expect(try SupabaseRecordRepository.decoder.decode(HomeworkRow.self, from: homework).record.status == .notDone)
    }

    @Test func placementParamsForceTheKindAndCarryTheStatus() {
        let student = UUID()
        let placement = PlacementRecord(
            studentID: student,
            checks: [.init(studentID: student, skillID: UUID(), question: "Q", correct: false, isPlacement: false)],
            states: [], track: SessionClose.Track(status: .notKnown, reasons: [])
        )
        let params = SupabaseRecordRepository.placementParams(placement, centre: UUID())
        guard case let .array(checks)? = params["p_checks"], case let .object(first)? = checks.first else {
            Issue.record("no checks")
            return
        }
        #expect(first["kind"] == .string("placement"))
        #expect(params["p_track"] == .object(["status": .string("not_known"), "reasons": .array([])]))
        #expect(params["p_student"] == .string(student.uuidString.lowercased()))
        let untracked = PlacementRecord(studentID: student, checks: [], states: [], track: nil)
        #expect(SupabaseRecordRepository.placementParams(untracked, centre: UUID())["p_track"] == .object([:]))
    }

    @Test func aMessageEntryDecodesEveryKind() throws {
        let json = Data(#"""
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60811","kind":"consent","opened_at":"2026-10-05T10:00:00+00:00",
          "language":null},
         {"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60812","kind":"absence","opened_at":"2026-10-02T13:00:00+00:00",
          "language":"hi"},
         {"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60813","kind":"something_new","opened_at":"2026-10-02T13:00:00+00:00",
          "language":null}]
        """#.utf8)
        let entries = try SupabaseMessageLogRepository.decoder.decode([MessageEntryRow].self, from: json)
            .compactMap(\.entry)
        #expect(entries.map(\.kind) == [.consent, .absence] && entries[1].language == .hindi)
    }
}
