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
            failed(
                "Couldn't create the fees. Check your connection and try again.",
                .generateFees,
                error: error
            ) { [weak self] in
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
        let at = FeeInvoice.paidAt(for: day, today: today, now: now(), calendar: calendar)
        if await mustQueueMarkPaid() {
            return keepPaidHere(id, method: method, at: at)
        }
        do {
            let before = invoice(id)
            let paid = try await fees.markPaid(id: id, method: method, at: at)
            if before?.status == .waived, let reason = before?.waivedReason {
                reasonsBeforePaid[id] = reason
            }
            replace(paid)
            succeeded()
            undo = UndoToast(text: "\(firstName(of: paid))'s fee marked paid\(Self.by(method)).", invoiceID: id)
            let offersReceipt = workspace.centre.payments.sendReceipts && receipt(for: id)?.url != nil
            sheet = offersReceipt ? .receipt(id) : nil
            onFeesChanged()
            return true
        } catch {
            if queue != nil, TransportError.isOffline(error) {
                return keepPaidHere(id, method: method, at: at)
            }
            failed("Couldn't mark the fee paid. Check your connection and try again.") { [weak self] in
                _ = await self?.markPaid(id, method: method, on: day)
            }
            return false
        }
    }

    /// Undo: the one fee back as it was, nothing paid, a second write: due, or waived again with its reason.
    func undoPaid(_ id: UUID) async -> Bool {
        let name = invoice(id).map(firstName(of:)) ?? "The"
        undo = nil
        if keptHere.contains(id) {
            // Nothing was written: the change leaves the queue and the row is as it was (D39).
            undoKeptHere(id)
            return true
        }
        writing = true
        defer { writing = false }
        do {
            let restored = if let reason = reasonsBeforePaid[id] {
                try await fees.waive(id: id, reason: reason)
            } else {
                try await fees.markDue(id: id)
            }
            reasonsBeforePaid[id] = nil
            replace(restored)
            if sheet == .receipt(id) {
                sheet = nil
            }
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
            failed(
                "Couldn't waive the fee. Check your connection and try again.",
                .waiveFee,
                error: error
            ) { [weak self] in
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
            failed("Couldn't save. Check your connection and try again.", .editPayments, error: error) { [weak self] in
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

    internal func succeeded() {
        lastSavedAt = now()
        lastFailed = nil
        canRetry = false
    }

    private func failed(
        _ text: String, _ refusal: OfflineRefusal.Write? = nil, error: (any Error)? = nil,
        retry: @escaping @MainActor () async -> Void
    ) {
        if let error, let refusal, TransportError.isOffline(error) {
            // Offline: the write needs a connection; nothing was saved, and Retry would only fail again (D39).
            message = OfflineRefusal.words(for: refusal)
            canRetry = false
            lastFailed = nil
            return
        }
        message = text
        canRetry = true
        lastFailed = retry
    }
}
