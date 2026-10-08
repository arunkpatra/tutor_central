import Domain
import Foundation
import Testing
@testable import Data

/// The local stack's answer on 2026-10-08 to a progress log insert.
struct ProgressLogRowTests {
    static let logged = Data("""
    [{"student_id":"50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533","kind":"progress",\
    "opened_at":"2026-10-08T18:09:01.503638+00:00","about_date":null}]
    """.utf8)

    @Test func decodesTheOpenedAt() throws {
        let row = try #require(try SupabaseMessageLogRepository.decoder.decode([ProgressLogRow].self, from: Self.logged)
            .first)
        #expect(row.kind == "progress" && row.openedAt.timeIntervalSince1970 > 1_791_000_000)
        #expect(row.studentId == UUID(uuidString: "50bc8ac1-e0f6-4ec0-b2a8-fac8d1c60533"))
    }
}
