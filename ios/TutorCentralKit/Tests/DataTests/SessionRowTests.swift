import Domain
import Foundation
import Testing
@testable import Data

/// Every fixture here is what the local stack answered as the seed's tutor (2026-10-08): the month's read with the
/// marks embedded (PostgREST writes them with a space after each colon), the RPC's bare uuid, the message log's
/// insert and read.
struct SessionRowTests {
    static let json = Data("""
    [{"id":"d3f740a4-f181-427b-8b3e-f255b2392bd2","class_id":null,"date":"2026-10-03",\
    "saved_at":"2026-10-08T09:19:32.088189+00:00",\
    "attendance_marks":[{"status": "absent", "student_id": "94e00eca-e875-4131-b0bd-91568ee90b40"}]},
     {"id":"049a1727-2cb9-4a3d-a49c-b590a1a8860a","class_id":"33333333-3333-3333-3333-333333333331",\
    "date":"2026-10-02","saved_at":"2026-10-08T09:18:21.253113+00:00",\
    "attendance_marks":[{"status": "present", "student_id": "0e3e56a0-703a-41b8-9f41-589c629252e1"}, \
    {"status": "present", "student_id": "2756b941-6eaa-4e0c-96f0-0dbb599aa45a"}, \
    {"status": "absent", "student_id": "15936dd0-0045-4c35-b4d0-5b3f2b19ce9a"}, \
    {"status": "present", "student_id": "94e00eca-e875-4131-b0bd-91568ee90b40"}, \
    {"status": "present", "student_id": "ad66fefd-0fb9-47c7-8f9d-931a2f26041a"}, \
    {"status": "present", "student_id": "d94227a5-0b76-42d8-927f-b2db2b193772"}]}]
    """.utf8)
    static let hemanth = UUID(uuidString: "94e00eca-e875-4131-b0bd-91568ee90b40")!

    @Test func decodesSessionsWithTheirMarks() throws {
        let rows = try SupabaseAttendanceRepository.decoder.decode([SessionRow].self, from: Self.json)
        let sessions = rows.map(\.session)
        #expect(sessions[0].classID == nil && sessions[0].date == Day(year: 2026, month: 10, day: 3))
        #expect(sessions[0].marks == [Self.hemanth: .absent])
        #expect(sessions[1].classID == FakeClassesRepository.maths.id && sessions[1].date == Day(
            year: 2026,
            month: 10,
            day: 2
        ))
        #expect(sessions[1].presentCount == 5 && sessions[1].absentCount == 1 && sessions[1]
            .marks[Self.hemanth] == .present)
    }

    @Test func aSingleSessionDecodes() throws {
        let data = Data("""
        {"id":"d3f740a4-f181-427b-8b3e-f255b2392bd2","class_id":null,"date":"2026-10-03",\
        "saved_at":"2026-10-08T09:19:32.088189+00:00",\
        "attendance_marks":[{"status": "absent", "student_id": "94e00eca-e875-4131-b0bd-91568ee90b40"}]}
        """.utf8)
        let session = try SupabaseAttendanceRepository.decoder.decode(SessionRow.self, from: data).session
        #expect(session.id.uuidString.lowercased() == "d3f740a4-f181-427b-8b3e-f255b2392bd2" && session
            .absentCount == 1)
    }

    @Test func theRpcAnswersABareUuid() throws {
        let data = Data("\"d3f740a4-f181-427b-8b3e-f255b2392bd2\"".utf8)
        let id = try SupabaseAttendanceRepository.decoder.decode(UUID.self, from: data)
        #expect(id.uuidString.lowercased() == "d3f740a4-f181-427b-8b3e-f255b2392bd2")
    }

    @Test func marksEncodeAsTheFunctionWants() {
        let json = SupabaseAttendanceRepository.marksJSON([Self.hemanth: .absent])
        #expect(json == .object(["94e00eca-e875-4131-b0bd-91568ee90b40": .string("absent")]))
    }

    @Test func aLogRowDecodesAndARowWithoutAStudentIsDropped() throws {
        let inserted = Data("""
        {"student_id":"94e00eca-e875-4131-b0bd-91568ee90b40","opened_at":"2026-10-08T09:19:32.12192+00:00"}
        """.utf8)
        let made = try SupabaseMessageLogRepository.decoder.decode(LogRow.self, from: inserted).log
        #expect(made?.studentID == Self.hemanth)
        let read = Data("""
        [{"student_id":null,"opened_at":"2026-10-08T09:19:32.160512+00:00"},
         {"student_id":"94e00eca-e875-4131-b0bd-91568ee90b40","opened_at":"2026-10-08T09:19:32.12192+00:00"}]
        """.utf8)
        let logs = try SupabaseMessageLogRepository.decoder.decode([LogRow].self, from: read).compactMap(\.log)
        #expect(logs.map(\.studentID) == [Self.hemanth])
    }

    @Test func aLogCarriesTheDayItIsAbout() throws {
        // The local stack's answers after migration 0005: an insert about 30 September, an old row without the day.
        let inserted = Data("""
        {"student_id":"ccf28636-4356-4cfe-af5a-23b12dc01599","opened_at":"2026-10-08T11:24:45.348033+00:00",\
        "about_date":"2026-09-30"}
        """.utf8)
        let made = try SupabaseMessageLogRepository.decoder.decode(LogRow.self, from: inserted).log
        #expect(made?.aboutDate == Day(year: 2026, month: 9, day: 30))
        let old = Data("""
        [{"student_id":"ccf28636-4356-4cfe-af5a-23b12dc01599","opened_at":"2026-10-08T11:24:45.38443+00:00",\
        "about_date":null}]
        """.utf8)
        let logs = try SupabaseMessageLogRepository.decoder.decode([LogRow].self, from: old).compactMap(\.log)
        #expect(logs.first?.aboutDate == nil && logs.first?.day(in: DayHeading.india) == Day(
            year: 2026,
            month: 10,
            day: 8
        ))
    }
}
