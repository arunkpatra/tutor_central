import Domain
import Foundation
import Testing
@testable import Data

/// The stack's answer for three items (migrations 0011 and 0021): a student's, a school's class, a whole school.
struct SchoolItemRowTests {
    static let rows = Data("""
    [{"id":"66666666-6666-6666-6666-666666666661","kind":"exam","school_id":null,\
    "student_id":"55555555-5555-5555-5555-55555555555d","class_level":null,"title":"Science unit test",\
    "subject":"Science","date":"2026-10-08","end_date":null,"portions":"chapters 1 and 2","source_text":null,\
    "photo_path":null,"source":"typed","received_at":"2026-10-07T09:34:00+00:00",\
    "confirmed_at":"2026-10-07T09:34:00.123+00:00"},
    {"id":"66666666-6666-6666-6666-666666666662","kind":"homework",\
    "school_id":"44444444-4444-4444-4444-444444444441","student_id":null,"class_level":"8",\
    "title":"Maths Ex 3.2, Q1 to 10","subject":"Mathematics","date":"2026-10-12","end_date":null,\
    "portions":null,"source_text":"Dear Parents","photo_path":"c/item/x.jpg","source":"shared_text",\
    "received_at":"2026-10-07T09:34:00+00:00","confirmed_at":null},
    {"id":"66666666-6666-6666-6666-666666666663","kind":"holiday",\
    "school_id":"44444444-4444-4444-4444-444444444441","student_id":null,"class_level":null,\
    "title":"Dasara holidays","subject":null,"date":"2026-10-19","end_date":"2026-10-21","portions":null,\
    "source_text":null,"photo_path":null,"source":"fax","received_at":"2026-10-07T09:34:00+00:00",\
    "confirmed_at":"2026-10-07T09:34:00+00:00"}]
    """.utf8)

    @Test func aRowReadsIntoAnItemWithItsAudience() throws {
        let rows = try SupabaseSchoolItemsRepository.decoder.decode([SchoolItemRow].self, from: Self.rows)
        let items = rows.compactMap(\.item)
        #expect(items.count == 3)
        let student = try #require(UUID(uuidString: "55555555-5555-5555-5555-55555555555d"))
        let vidya = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444441"))
        #expect(items[0].audience == .student(student) && items[0].kind == .exam && items[0].confirmedAt != nil)
        #expect(items[1].audience == .schoolClass(school: vidya, level: .eight) && items[1].source == .sharedText)
        #expect(items[1].photoPath == "c/item/x.jpg" && items[1].sourceText == "Dear Parents" && items[1]
            .confirmedAt == nil)
        #expect(items[2].audience == .school(vidya) && items[2].endDate == Day(year: 2026, month: 10, day: 21))
        #expect(items[2].source == .typed, "an unknown source word reads as typed")
        #expect(items[0].date == Day(year: 2026, month: 10, day: 8) && items[0].portions == "chapters 1 and 2")
    }

    @Test func aRowWhoseSchoolWentReadsAsNoItem() throws {
        let orphan = Data("""
        [{"id":"66666666-6666-6666-6666-666666666664","kind":"exam","school_id":null,"student_id":null,\
        "class_level":"9",        "title":"Test","subject":"Science","date":"2026-10-08","end_date":null,\
        "portions":null,"source_text":null,"photo_path":null,"source":"typed",\
        "received_at":"2026-10-07T09:34:00+00:00","confirmed_at":null}]
        """.utf8)
        let rows = try SupabaseSchoolItemsRepository.decoder.decode([SchoolItemRow].self, from: orphan)
        #expect(rows.compactMap(\.item).isEmpty)
    }

    @Test func aSharedDraftWritesWhenItWasShared() throws {
        var draft = SchoolItemDraft(
            kind: .notice, audience: .school(UUID()), title: "PTM", subject: nil, date: Day(
                year: 2026,
                month: 10,
                day: 9
            ),
            source: .sharedText
        )
        draft.receivedAt = Date(timeIntervalSince1970: 0)
        let json = try #require(String(
            bytes: JSONEncoder().encode(SchoolItemWrite(
                draft: draft,
                photoPath: nil,
                centre: UUID(),
                confirmedAt: Date()
            )),
            encoding: .utf8
        ))
        #expect(json.contains("\"received_at\":\"1970-01-01T00:00:00Z\""))
    }

    @Test func aDraftWritesItsAudienceAsColumns() throws {
        let vidya = try #require(UUID(uuidString: "44444444-4444-4444-4444-444444444441"))
        let draft = SchoolItemDraft(
            kind: .holiday, audience: .school(vidya), title: "Dasara holidays", subject: nil,
            date: Day(year: 2026, month: 10, day: 19), endDate: Day(year: 2026, month: 10, day: 21), source: .sharedText
        )
        let write = SchoolItemWrite(
            draft: draft,
            photoPath: nil,
            centre: vidya,
            confirmedAt: Date(timeIntervalSince1970: 0)
        )
        let json = try #require(String(bytes: JSONEncoder().encode(write), encoding: .utf8))
        #expect(json.contains("\"school_id\":\"44444444-4444-4444-4444-444444444441\"") && json
            .contains("\"class_level\":null"))
        #expect(json.contains("\"end_date\":\"2026-10-21\"") && json.contains("\"source\":\"shared_text\""))
        #expect(json.contains("\"student_id\":null") && json.contains("\"confirmed_at\":\"1970-01-01T00:00:00Z\""))
    }
}
