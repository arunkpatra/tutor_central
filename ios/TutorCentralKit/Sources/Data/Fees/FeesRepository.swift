import Domain
import Foundation

/// The fee ledger. RLS keeps every call inside the member's centre.
public protocol FeesRepository: Sendable {
    /// The month's fees, by student id (the caller orders by name).
    func invoices(centre: UUID, month: Period) async throws -> [FeeInvoice]
    /// One student's months, newest first.
    func invoices(centre: UUID, student: UUID) async throws -> [FeeInvoice]
    /// Fees still due from months before `month` (the overdue banner).
    func dueBefore(centre: UUID, month: Period) async throws -> [FeeInvoice]
    /// `generate_fees`; how many it made.
    func generate(centre: UUID, month: Period) async throws -> Int
    /// Paid at `at` (now, or the chosen day at noon); clears a waive reason.
    func markPaid(id: UUID, method: MonthFee.PaidMethod, at: Date) async throws -> FeeInvoice
    /// Undo: due, nothing paid.
    func markDue(id: UUID) async throws -> FeeInvoice
    /// Waived with its reason; nothing paid.
    func waive(id: UUID, reason: String) async throws -> FeeInvoice
}
