import Domain
import Foundation
import Testing
@testable import Data

/// The stack's answers on 2026-10-08 as the seed's tutor: a reminder's insert (every column) and the month's read.
/// Long lines are joined with `\`, nothing changed.
struct FeeLogRowTests {
    static let inserted = Data("""
    [{"id":"69ce3185-4fca-4d3b-becd-f47e0c1a43b7","centre_id":"22222222-2222-2222-2222-222222222222",\
    "student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder","channel":"whatsapp_link",\
    "opened_at":"2026-10-08T13:11:45.759711+00:00","created_at":"2026-10-08T13:11:45.759711+00:00",\
    "updated_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]
    """.utf8)
    static let read = Data("""
    [{"student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder",\
    "opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]
    """.utf8)

    @Test func decodesAFeeLogFromTheInsertAndTheRead() throws {
        let decoder = SupabaseMessageLogRepository.decoder
        let made = try #require(try decoder.decode([FeeLogRow].self, from: Self.inserted).first?.log)
        #expect(made.kind == .reminder && made.month == Period(year: 2026, month: 10))
        #expect(made.studentID.uuidString.lowercased() == "11f29474-3413-4c2c-a045-4fa4fd181b19")
        let read = try decoder.decode([FeeLogRow].self, from: Self.read).compactMap(\.log)
        #expect(read.count == 1 && Day(read[0].openedAt, calendar: DayHeading.india) == Day(
            year: 2026,
            month: 10,
            day: 8
        ))
    }

    @Test func aLogWithoutAStudentOrAMonthTellsNoOne() throws {
        let decoder = SupabaseMessageLogRepository.decoder
        let orphan = Data(#"""
        [{"student_id":null,"kind":"receipt","opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":"2026-10-01"}]
        """#.utf8)
        #expect(try decoder.decode([FeeLogRow].self, from: orphan).compactMap(\.log).isEmpty)
        let old = Data(#"""
        [{"student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","kind":"reminder",\#
        "opened_at":"2026-10-08T13:11:45.759711+00:00","about_date":null}]
        """#.utf8)
        #expect(
            try decoder.decode([FeeLogRow].self, from: old).compactMap(\.log).isEmpty,
            "a reminder before this build named no month"
        )
    }
}
