import Domain
import Foundation

/// A `fee_invoices` row as PostgREST answers it; a write's answer carries the centre and timestamps too, which are
/// ignored.
struct InvoiceRow: Decodable {
    let id: UUID
    let studentId: UUID
    let period: String
    let amount: Int
    let status: String
    let paidAt: Date?
    let paidMethod: String?
    let waivedReason: String?

    /// Nil for a status this build does not know (never, by the enum; kept so a bad row cannot crash the ledger).
    var invoice: FeeInvoice? {
        guard let period = Period(isoDay: period), let status = MonthFee.Status(rawValue: status) else { return nil }
        return FeeInvoice(
            id: id, studentID: studentId, period: period, amount: Money(rupees: amount), status: status, paidAt: paidAt,
            paidMethod: paidMethod.flatMap(MonthFee.PaidMethod.init(rawValue:)), waivedReason: waivedReason
        )
    }
}
