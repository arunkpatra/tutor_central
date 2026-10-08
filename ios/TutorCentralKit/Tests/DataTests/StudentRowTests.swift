import Domain
import Foundation
import Testing
@testable import Data

struct StudentRowTests {
    static let json = Data("""
    [{"id":"aaaaaaaa-0000-0000-0000-000000000001","name":"Akshita Rao",
      "class_id":"33333333-3333-3333-3333-333333333331","monthly_fee":null,"parent_name":"Priya Rao",
      "parent_phone":"+919799113211","date_of_birth":null,"gender":null,"notes":null,"archived_at":null,
      "fee_invoices":[{"amount":1200,"status":"paid","paid_at":"2026-10-04T13:00:00+00:00","paid_method":"upi"}]},
     {"id":"aaaaaaaa-0000-0000-0000-000000000009","name":"Riya Sharma",
      "class_id":"33333333-3333-3333-3333-333333333331","monthly_fee":1500,"parent_name":"Neha Sharma",
      "parent_phone":"+919811122233","date_of_birth":"2011-03-14","gender":"female",
      "notes":"Board exam in March.","archived_at":"2026-10-07T12:00:00+00:00","fee_invoices":[]}]
    """.utf8)

    @Test func decodesPostgRESTRowsIntoStudents() throws {
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: Self.json)
        let akshita = rows[0].student(calendar: DayHeading.india)
        #expect(akshita.name == "Akshita Rao" && akshita.monthlyFee == nil && akshita.parentPhone?
            .display == "+91 97991 13211")
        #expect(akshita.thisMonth == MonthFee(
            amount: Money(rupees: 1200),
            status: .paid,
            paidOn: Day(year: 2026, month: 10, day: 4),
            paidMethod: .upi
        ))
        let riya = rows[1].student(calendar: DayHeading.india)
        #expect(riya.monthlyFee == Money(rupees: 1500) && riya.dateOfBirth == Day(year: 2011, month: 3, day: 14) && riya
            .gender == .female)
        #expect(riya.isArchived && riya.thisMonth == nil && riya.notes == "Board exam in March.")
    }

    @Test func readsPostgRESTMicroseconds() throws {
        // What the local stack answers: six fractional digits.
        let json = Self.json.replacingOccurrences(
            of: "2026-10-04T13:00:00+00:00",
            with: "2026-10-04T13:10:51.285947+00:00"
        )
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: json)
        #expect(rows[0].student(calendar: DayHeading.india).thisMonth?.paidOn == Day(year: 2026, month: 10, day: 4))
    }

    /// Review, Critical: an insert or update answers the student's columns without `fee_invoices`; it must decode.
    @Test func aRowWithoutItsInvoicesDecodes() throws {
        let json = Data("""
        {"id":"aaaaaaaa-0000-0000-0000-000000000011","name":"Zara Khan","class_id":null,"monthly_fee":null,
         "parent_name":null,"parent_phone":null,"date_of_birth":null,"gender":null,"notes":null,"archived_at":null}
        """.utf8)
        let row = try SupabaseStudentsRepository.decoder.decode(StudentRow.self, from: json)
        #expect(row.student(calendar: DayHeading.india).name == "Zara Khan" && row.student(calendar: DayHeading.india)
            .thisMonth == nil)
    }

    @Test func aPaymentLateInTheEveningIsStillThatDayInIndia() throws {
        // 20:30 UTC on 4 October is 02:00 on 5 October in India.
        let json = Self.json.replacingOccurrences(of: "2026-10-04T13:00:00+00:00", with: "2026-10-04T20:30:00+00:00")
        let rows = try SupabaseStudentsRepository.decoder.decode([StudentRow].self, from: json)
        #expect(rows[0].student(calendar: DayHeading.india).thisMonth?.paidOn == Day(year: 2026, month: 10, day: 5))
    }
}

private extension Data {
    func replacingOccurrences(of target: String, with replacement: String) -> Data {
        Data((String(bytes: self, encoding: .utf8) ?? "").replacingOccurrences(of: target, with: replacement).utf8)
    }
}
