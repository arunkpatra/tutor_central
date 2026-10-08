import Data
import Domain
import Foundation

/// What the message sheets show (P5-Remind, P5-Receipt): the student, the parent and number (or what is missing), the
/// text, and the WhatsApp link when there is a number.
public struct FeeMessageSheet: Hashable, Sendable, Identifiable {
    public let invoiceID: UUID
    public let kind: FeeLog.Kind
    public let student: Student
    public let title: String
    public let headline: String
    public let parentLine: String
    public let label: String
    public let text: String
    public let note: String
    public let url: URL?
    public var id: UUID {
        invoiceID
    }
}

/// The reminder and the receipt (components.md, the parent-facing texts), logged before the link opens (D3).
public extension FeesStore {
    /// The reminder for a fee still due or overdue; nil once it is settled or gone.
    func reminder(for id: UUID) -> FeeMessageSheet? {
        guard let invoice = invoice(id), !invoice.state(current: today.period).isSettled,
              let student = register.student(invoice.studentID) else { return nil }
        let payments = workspace.centre.payments
        let text = FeeMessage(
            kind: .reminder, parentName: student.parentName, studentName: student.name, month: invoice.period,
            amount: invoice.amount, upiID: payments.upiID, paymentLink: payments.paymentLink,
            tutorName: workspace.profile.displayName, centreName: workspace.centre.name
        ).text
        return FeeMessageSheet(
            invoiceID: id, kind: .reminder, student: student, title: "Remind the parent",
            headline: "\(student.firstName)'s \(invoice.period.monthName) fee is due",
            parentLine: parentLine(student), label: "Message", text: text,
            note: "Opens WhatsApp with the message ready to send. We note the date on the fee. "
                + "The text is copied too, in case WhatsApp can't open.",
            url: student.parentPhone.map { AbsenceMessage.whatsAppURL(phone: $0, text: text) }
        )
    }

    /// The receipt for a paid fee; nil unless it is paid. Mark paid opens it only when receipts are on and the parent
    /// has a number.
    func receipt(for id: UUID) -> FeeMessageSheet? {
        guard let invoice = invoice(id), invoice.status == .paid, let student = register.student(invoice.studentID),
              let day = invoice.paidOn(calendar: calendar) else { return nil }
        let text = FeeMessage(
            kind: .receipt(method: invoice.paidMethod ?? .other, day: day), parentName: student.parentName,
            studentName: student.name, month: invoice.period, amount: invoice.amount, upiID: nil, paymentLink: nil,
            tutorName: workspace.profile.displayName, centreName: workspace.centre.name
        ).text
        return FeeMessageSheet(
            invoiceID: id, kind: .receipt, student: student, title: "Send a receipt",
            headline: "\(student.firstName)'s fee is paid", parentLine: parentLine(student), label: "Receipt",
            text: text, note: "Opens WhatsApp with the receipt ready to send. We note it on the fee.",
            url: student.parentPhone.map { AbsenceMessage.whatsAppURL(phone: $0, text: text) }
        )
    }

    /// Logs the message about its fee's month, then hands back the link to open. Nil, with a toast, when it could not
    /// be logged.
    func send(_ sheet: FeeMessageSheet) async -> URL? {
        guard let url = sheet.url, let invoice = invoice(sheet.invoiceID) else { return nil }
        do {
            let log = try await messages.logFee(
                centre: workspace.centre.id, studentID: sheet.student.id, kind: sheet.kind, month: invoice.period
            )
            logs.insert(log, at: 0)
            lastSavedAt = now()
            return url
        } catch {
            message = "Couldn't open WhatsApp. Check your connection and try again."
            canRetry = false
            return nil
        }
    }

    private func parentLine(_ student: Student) -> String {
        guard student.parentPhone != nil else { return "Add the parent's number first" }
        return Self.parentLine(student) ?? "Add the parent's number first"
    }
}
