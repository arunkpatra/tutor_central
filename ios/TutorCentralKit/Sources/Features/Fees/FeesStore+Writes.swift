import Data
import Domain
import Foundation

/// The writes: each waits for the server; a failure says what happened, keeps the fee as it was and offers Retry.
public extension FeesStore {
    /// `generate_fees` for the shown month; the toast says how many, and the month is read again.
    @discardableResult
    func generate() async -> Int? {
        writing = true
        defer { writing = false }
        do {
            let count = try await fees.generate(centre: workspace.centre.id, month: month)
            sheet = nil
            succeeded()
            message = "\(count) \(count == 1 ? "fee" : "fees") created for \(month.monthName)."
            await reload()
            onFeesChanged()
            return count
        } catch {
            failed("Couldn't create the fees. Check your connection and try again.") { [weak self] in
                _ = await self?.generate()
            }
            return nil
        }
    }

    /// Paid by `method` on `day` (today is now; an earlier day is its noon). The row moves, the toast offers Undo, and
    /// the receipt sheet opens when receipts are on and the parent has a number.
    func markPaid(_ id: UUID, method: MonthFee.PaidMethod, on day: Day) async -> Bool {
        writing = true
        defer { writing = false }
        do {
            let at = FeeInvoice.paidAt(for: day, today: today, now: now(), calendar: calendar)
            let paid = try await fees.markPaid(id: id, method: method, at: at)
            replace(paid)
            succeeded()
            undo = UndoToast(text: "\(firstName(of: paid))'s fee marked paid\(Self.by(method)).", invoiceID: id)
            let offersReceipt = workspace.centre.payments.sendReceipts && receipt(for: id)?.url != nil
            sheet = offersReceipt ? .receipt(id) : nil
            onFeesChanged()
            return true
        } catch {
            failed("Couldn't mark the fee paid. Check your connection and try again.") { [weak self] in
                _ = await self?.markPaid(id, method: method, on: day)
            }
            return false
        }
    }

    /// Undo: the one fee back to due, nothing paid, a second write.
    func undoPaid(_ id: UUID) async -> Bool {
        let name = invoice(id).map(firstName(of:)) ?? "The"
        undo = nil
        writing = true
        defer { writing = false }
        do {
            let due = try await fees.markDue(id: id)
            replace(due)
            succeeded()
            onFeesChanged()
            return true
        } catch {
            failed("Couldn't undo. \(name)'s fee stays paid.") { [weak self] in _ = await self?.undoPaid(id) }
            return false
        }
    }

    /// Waived with the reason (trimmed, 1 to 200 characters): settled, not collected.
    func waive(_ id: UUID, reason: String) async -> Bool {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= FeeInvoice.waiveReasonLimit else { return false }
        writing = true
        defer { writing = false }
        do {
            let waived = try await fees.waive(id: id, reason: trimmed)
            replace(waived)
            succeeded()
            sheet = nil
            message = "\(firstName(of: waived))'s fee waived."
            onFeesChanged()
            return true
        } catch {
            failed("Couldn't waive the fee. Check your connection and try again.") { [weak self] in
                _ = await self?.waive(id, reason: trimmed)
            }
            return false
        }
    }

    /// "That's right" on the payee card: the UPI id confirmed now.
    func confirmPayee() async {
        confirming = true
        defer { confirming = false }
        do {
            let at = now()
            try await centres.confirmUPI(id: workspace.centre.id, at: at)
            workspace.centre.payments.upiConfirmedAt = at
            succeeded()
            onWorkspaceChanged(workspace)
        } catch {
            failed("Couldn't save. Check your connection and try again.") { [weak self] in
                await self?.confirmPayee()
            }
        }
    }

    private static func by(_ method: MonthFee.PaidMethod) -> String {
        switch method {
        case .upi: " by UPI"
        case .cash: " by cash"
        case .other: ""
        }
    }

    private func succeeded() {
        lastSavedAt = now()
        lastFailed = nil
        canRetry = false
    }

    private func failed(_ text: String, retry: @escaping @MainActor () async -> Void) {
        message = text
        canRetry = true
        lastFailed = retry
    }
}
