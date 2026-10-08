import Domain
import Foundation
import Testing
@testable import Data

/// Every fixture here is what the local stack answered as the seed's tutor (2026-10-08): the month's read, a mark paid
/// answer with every column, a waive answer with the read's columns. Long lines are joined with `\`, nothing changed.
struct InvoiceRowTests {
    static let month = Data("""
    [{"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19",\
    "period":"2026-10-01","amount":1000,"status":"due","paid_at":null,"paid_method":null,"waived_reason":null},
     {"id":"98ae7ca8-94dc-47db-aa65-d46ffc6e61a8","student_id":"2bf34b2d-af1c-4510-a784-452c8415ec89",\
    "period":"2026-10-01","amount":1200,"status":"paid","paid_at":"2026-10-05T11:28:56.803636+00:00",\
    "paid_method":"upi","waived_reason":null},
     {"id":"fc5083f6-ce30-46af-9851-25159e5d745f","student_id":"3611371e-6814-446a-ba55-affd7aa460ec",\
    "period":"2026-10-01","amount":1200,"status":"paid","paid_at":"2026-10-05T11:28:56.803636+00:00",\
    "paid_method":"upi","waived_reason":null}]
    """.utf8)
    static let paid = Data("""
    [{"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","centre_id":"22222222-2222-2222-2222-222222222222",\
    "student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19","period":"2026-10-01","amount":1000,"status":"paid",\
    "paid_at":"2026-10-07T07:30:00+00:00","paid_method":"upi","waived_reason":null,\
    "created_at":"2026-10-08T11:28:56.803636+00:00","updated_at":"2026-10-08T13:11:45.819826+00:00"}]
    """.utf8)
    static let waived = Data("""
    {"id":"0ac1dcb5-b76b-4bd9-b43b-4b3639589b14","student_id":"11f29474-3413-4c2c-a045-4fa4fd181b19",\
    "period":"2026-10-01","amount":1000,"status":"waived","paid_at":null,"paid_method":null,\
    "waived_reason":"Joined mid-month"}
    """.utf8)

    @Test func decodesAMonthWithPaidAndDueRows() throws {
        let rows = try SupabaseFeesRepository.decoder.decode([InvoiceRow].self, from: Self.month).compactMap(\.invoice)
        #expect(rows.count == 3 && rows[0].status == .due && rows[0].paidAt == nil)
        #expect(rows[0].amount == Money(rupees: 1000) && rows[0].period == Period(year: 2026, month: 10))
        #expect(rows[0].id.uuidString.lowercased() == "0ac1dcb5-b76b-4bd9-b43b-4b3639589b14")
        #expect(rows[1].status == .paid && rows[1].paidMethod == .upi)
        #expect(rows[1].paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 5))
    }

    @Test func decodesAWriteAnswerWithEveryColumnOrAFew() throws {
        let paid = try #require(try SupabaseFeesRepository.decoder.decode([InvoiceRow].self, from: Self.paid).first?
            .invoice)
        #expect(paid.status == .paid && paid.paidMethod == .upi && paid.waivedReason == nil)
        #expect(
            paid.paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 7),
            "07:30Z is 13:00 in India, the 7th"
        )
        let waived = try #require(try SupabaseFeesRepository.decoder.decode(InvoiceRow.self, from: Self.waived).invoice)
        #expect(waived.status == .waived && waived.waivedReason == "Joined mid-month" && waived.paidAt == nil)
    }

    @Test func theRpcAnswersACount() throws {
        #expect(try SupabaseFeesRepository.decoder.decode(Int.self, from: Data("0".utf8)) == 0)
        #expect(try SupabaseFeesRepository.decoder.decode(Int.self, from: Data("10".utf8)) == 10)
    }
}
