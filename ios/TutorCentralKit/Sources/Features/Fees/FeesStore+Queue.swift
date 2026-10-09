import Data
import Domain
import Foundation

/// Mark paid offline (D39): kept on this iPhone and sent in order when the network returns; Undo takes it out of the
/// queue, nothing having been written.
extension FeesStore {
    /// Offline, or a Mark paid already waits (so an older one can never overtake a newer one).
    func mustQueueMarkPaid() async -> Bool {
        guard let queue else { return false }
        if queue.pending.has(kind: .markPaid) {
            return true
        }
        return await !online()
    }

    func keepPaidHere(_ id: UUID, method: MonthFee.PaidMethod, at: Date) -> Bool {
        guard let queue, let before = invoice(id) else { return false }
        let name = register.student(before.studentID)?.name ?? firstName(of: before)
        queue.add(QueuedChange(
            kind: .markPaid(
                invoiceID: id, studentName: name, month: before.period, amount: before.amount, method: method,
                paidAt: at
            ),
            madeAt: now()
        ))
        beforeKept[id] = before
        replace(Self.paid(before, method: method, at: at))
        keptHere.insert(id)
        succeeded()
        undo = UndoToast(
            text: "\(firstName(of: before))'s fee marked paid here. It's sent when you're back online.",
            invoiceID: id
        )
        // No receipt offline: its log could not be noted.
        sheet = nil
        return true
    }

    func undoKeptHere(_ id: UUID) {
        if let change = queue?.pending.changes.first(where: { Self.invoiceID(of: $0) == id }) {
            queue?.remove(id: change.id)
        }
        if let before = beforeKept.removeValue(forKey: id) {
            replace(before)
        }
        keptHere.remove(id)
    }

    /// A read while changes wait: the fees marked here still read paid here, until they are sent.
    func overlayQueued() {
        let waiting = (queue?.pending.changes ?? []).filter { $0.state == .waiting }
        keptHere = []
        for change in waiting {
            guard case let .markPaid(id, _, _, _, method, paidAt) = change.kind, let current = invoice(id) else {
                continue
            }
            if current.status != .paid {
                beforeKept[id] = current
                replace(Self.paid(current, method: method, at: paidAt))
            }
            keptHere.insert(id)
        }
    }

    static func paid(_ invoice: FeeInvoice, method: MonthFee.PaidMethod, at: Date) -> FeeInvoice {
        FeeInvoice(
            id: invoice.id, studentID: invoice.studentID, period: invoice.period, amount: invoice.amount,
            status: .paid, paidAt: at, paidMethod: method, waivedReason: nil
        )
    }

    static func invoiceID(of change: QueuedChange) -> UUID? {
        guard case let .markPaid(id, _, _, _, _, _) = change.kind else { return nil }
        return id
    }
}
