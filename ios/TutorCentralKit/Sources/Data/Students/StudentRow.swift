import Domain
import Foundation

/// A `students` row with this month's invoice embedded (`fee_invoices(amount, status, paid_at)` filtered by period).
struct StudentRow: Decodable {
    struct Invoice: Decodable {
        let amount: Int
        let status: String
        let paidAt: Date?
        let paidMethod: String?
    }

    let id: UUID
    let name: String
    let classId: UUID?
    let monthlyFee: Int?
    let parentName: String?
    let parentPhone: String?
    let dateOfBirth: String?
    let gender: String?
    let notes: String?
    let archivedAt: Date?
    /// Absent on an insert's or update's answer, which selects the student's columns only.
    let feeInvoices: [Invoice]?

    func student(calendar: Calendar) -> Student {
        Student(
            id: id,
            name: name,
            classID: classId,
            monthlyFee: monthlyFee.map(Money.init(rupees:)),
            parentName: parentName,
            parentPhone: parentPhone.flatMap(PhoneNumber.init(e164:)),
            dateOfBirth: dateOfBirth.flatMap(Day.init(iso:)),
            gender: gender.flatMap(Gender.init(rawValue:)),
            notes: notes,
            archivedAt: archivedAt,
            thisMonth: feeInvoices?.first.flatMap { invoice in
                MonthFee.Status(rawValue: invoice.status).map {
                    MonthFee(
                        amount: Money(rupees: invoice.amount),
                        status: $0,
                        paidOn: invoice.paidAt.map { Day($0, calendar: calendar) },
                        paidMethod: invoice.paidMethod.flatMap(MonthFee.PaidMethod.init(rawValue:))
                    )
                }
            }
        )
    }
}
