import Domain
import Foundation
import Supabase
import Testing
@testable import Data

struct SessionCloseParamsTests {
    let student = UUID(uuidString: "94e00eca-e875-4131-b0bd-91568ee90b40")!
    let skill = UUID(uuidString: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60751")!

    @Test func theCloseIsSentAsCloseSessionTakesIt() throws {
        let check = SessionClose.Check(
            studentID: student, skillID: skill, question: "Half of 8?", correct: true, isPlacement: false
        )
        let close = try SessionClose(
            classID: nil, date: #require(Day(year: 2026, month: 10, day: 12)), marks: [student: .present],
            checks: [check],
            homework: [.init(studentID: student, artefactID: nil)],
            track: [student: .init(status: .onTrack, reasons: ["checks"])]
        )
        let params = SupabaseAttendanceRepository.closeParams(close, centre: FakeSchoolsRepository.centre)
        let id = student.uuidString.lowercased()
        #expect(params["p_class"] == .null && params["p_date"] == .string("2026-10-12"))
        #expect(params["p_marks"] == .object([id: .string("present")]))
        let sent: AnyJSON = .object([
            "student_id": .string(id),
            "skill_id": .string(skill.uuidString.lowercased()),
            "question": .object(["text": .string("Half of 8?")]),
            "correct": .bool(true),
            "kind": .string("check"),
        ])
        #expect(params["p_checks"] == .array([sent]))
        #expect(params["p_homework"] == .array([.object(["student_id": .string(id), "status": .string("given")])]))
        let track: AnyJSON = .object(["status": .string("on_track"), "reasons": .array([.string("checks")])])
        #expect(params["p_track"] == .object([id: track]))
    }

    @MainActor @Test func theFakeRecordsTheCloseAsAttendance() async throws {
        let repo = FakeAttendanceRepository()
        let close = try SessionClose(
            classID: FakeClassesRepository.maths.id, date: #require(Day(year: 2026, month: 10, day: 12)),
            marks: [student: .absent], checks: [], homework: [], track: [:]
        )
        let id = try await repo.close(close, centre: FakeSchoolsRepository.centre)
        #expect(repo.closes == [close])
        let sessions = try await repo.sessions(
            centre: FakeSchoolsRepository.centre,
            month: Period(year: 2026, month: 10)
        )
        #expect(sessions.first { $0.id == id }?.marks == [student: .absent])
    }

    @Test func closeParamsCarryTheStates() throws {
        let close = try SessionClose(
            classID: UUID(), date: #require(Day(year: 2026, month: 10, day: 7)), marks: [:], checks: [], homework: [],
            track: [:], states: [SkillStateChange(skillID: skill, state: .secure)]
        )
        let params = SupabaseAttendanceRepository.closeParams(close, centre: UUID())
        let state: AnyJSON = .object(["skill_id": .string(skill.uuidString.lowercased()), "state": .string("secure")])
        #expect(params["p_states"] == .array([state]))
    }
}
