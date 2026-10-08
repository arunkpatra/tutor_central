import Foundation

/// One row of `fee_invoices`: a student's fee for a month, due until paid or waived.
public struct FeeInvoice: Hashable, Sendable, Identifiable, Codable {
    public static let waiveReasonLimit = 200
    public let id: UUID
    public let studentID: UUID
    public let period: Period
    public let amount: Money
    public let status: MonthFee.Status
    public let paidAt: Date?
    public let paidMethod: MonthFee.PaidMethod?
    public let waivedReason: String?

    public init(
        id: UUID, studentID: UUID, period: Period, amount: Money, status: MonthFee.Status, paidAt: Date?,
        paidMethod: MonthFee.PaidMethod?, waivedReason: String?
    ) {
        self.id = id
        self.studentID = studentID
        self.period = period
        self.amount = amount
        self.status = status
        self.paidAt = paidAt
        self.paidMethod = paidMethod
        self.waivedReason = waivedReason
    }

    /// A due fee of a month before the current one is overdue (design-tokens.md, Numbers in code).
    public func state(current: Period) -> FeeState {
        switch status {
        case .paid: .paid
        case .waived: .waived
        case .due: period < current ? .overdue : .due
        }
    }

    public func paidOn(calendar: Calendar) -> Day? {
        paidAt.map { Day($0, calendar: calendar) }
    }

    /// Today's payment is now; an earlier day's is that day at noon, so it reads back as chosen (P5-MarkPaid's day).
    public static func paidAt(for day: Day, today: Day, now: Date, calendar: Calendar) -> Date {
        guard day != today else { return now }
        return calendar.date(byAdding: .hour, value: 12, to: day.date(in: calendar)) ?? now
    }

    /// The fee row's second line once settled (components.md, Fee row).
    public func settledLine(calendar: Calendar) -> String? {
        switch status {
        case .due: return nil
        case .waived: return "Waived · \(waivedReason ?? "")"
        case .paid:
            let day = paidOn(calendar: calendar).map { " on \($0.shortText)" } ?? ""
            switch paidMethod {
            case .upi: return "Paid by UPI\(day)"
            case .cash: return "Paid by cash\(day)"
            case .other, nil: return "Paid\(day)"
            }
        }
    }
}

/// How a fee stands today: the chip's word and tone.
public enum FeeState: Hashable, Sendable, CaseIterable {
    case due
    case overdue
    case paid
    case waived

    public var word: String {
        switch self {
        case .due: "Due"
        case .overdue: "Overdue"
        case .paid: "Paid"
        case .waived: "Waived"
        }
    }

    /// Paid or waived: nothing left to collect.
    public var isSettled: Bool {
        self == .paid || self == .waived
    }
}
