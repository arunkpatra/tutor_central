/// One month's invoice for a student (`fee_invoices` for the current period), as the register reads it; Phase 5 owns
/// the ledger.
public struct MonthFee: Hashable, Sendable, Codable {
    public enum Status: String, Hashable, Sendable, Codable { case due, paid, waived }

    public enum PaidMethod: String, Hashable, Sendable, Codable {
        case upi, cash, other

        public var label: String {
            switch self {
            case .upi: "UPI"
            case .cash: "cash"
            case .other: "other"
            }
        }
    }

    public let amount: Money
    public let status: Status
    public let paidOn: Day?
    public let paidMethod: PaidMethod?

    public init(amount: Money, status: Status, paidOn: Day?, paidMethod: PaidMethod? = nil) {
        self.amount = amount
        self.status = status
        self.paidOn = paidOn
        self.paidMethod = paidMethod
    }
}

/// The word under a student's fee in a row: "Paid 4 Oct" (ok), "Due" (due), "Waived" (neutral).
public enum FeeMark: Hashable, Sendable {
    case paid(on: Day)
    case due
    case waived

    public var text: String {
        switch self {
        case let .paid(day): "Paid \(day.shortText)"
        case .due: "Due"
        case .waived: "Waived"
        }
    }
}
