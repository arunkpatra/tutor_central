import Foundation

/// The Fees tab's three filters (P5-Fees-All, -Due, -Paid).
public enum FeeFilter: Hashable, Sendable, CaseIterable {
    case all
    case due
    case paid

    public var title: String {
        switch self {
        case .all: "All"
        case .due: "Due"
        case .paid: "Paid"
        }
    }
}

/// The money pair over a month (components.md, Money pair hero): outstanding is due and overdue, collected is paid
/// only; a waived fee is settled, not collected.
public struct FeeTotals: Hashable, Sendable {
    public let outstanding: Money
    public let outstandingCount: Int
    public let collected: Money
    public let paidCount: Int
    public let total: Int

    public init(invoices: [FeeInvoice]) {
        let due = invoices.filter { $0.status == .due }
        let paid = invoices.filter { $0.status == .paid }
        outstanding = due.map(\.amount).total
        outstandingCount = due.count
        collected = paid.map(\.amount).total
        paidCount = paid.count
        total = invoices.count
    }

    public var outstandingLine: String {
        switch outstandingCount {
        case 0: "Nothing due"
        case 1: "1 parent"
        default: "\(outstandingCount) parents"
        }
    }

    public var collectedLine: String {
        "\(paidCount) of \(total) paid"
    }
}

/// The earlier months' due fees, for the current month's banner (components.md, Overdue banner).
public struct OverdueSummary: Hashable, Sendable {
    public let amount: Money
    public let parents: Int
    public let latest: Period
    public let months: Int

    public var text: String {
        let from = months > 1 ? "\(latest.monthName) and before" : latest.monthName
        return "\(amount.formatted) overdue from \(from) · \(parents == 1 ? "1 parent" : "\(parents) parents")"
    }
}

public enum FeeLedger {
    /// A filter's rows: All is due and overdue first, then paid, then waived, each group by name.
    public static func rows(
        _ invoices: [FeeInvoice], filter: FeeFilter, current: Period, name: (UUID) -> String
    ) -> [FeeInvoice] {
        let kept = invoices.filter { invoice in
            switch filter {
            case .all: true
            case .due: !invoice.state(current: current).isSettled
            case .paid: invoice.status == .paid
            }
        }
        func rank(_ invoice: FeeInvoice) -> Int {
            switch invoice.status {
            case .due: 0
            case .paid: 1
            case .waived: 2
            }
        }
        return kept.sorted { lhs, rhs in
            guard rank(lhs) == rank(rhs) else { return rank(lhs) < rank(rhs) }
            return name(lhs.studentID).localizedCaseInsensitiveCompare(name(rhs.studentID)) == .orderedAscending
        }
    }

    public static func title(count: Int, filter: FeeFilter) -> String {
        switch filter {
        case .all: "\(count) \(count == 1 ? "fee" : "fees")"
        case .due: "\(count) due"
        case .paid: "\(count) paid"
        }
    }

    public static func overdueBefore(_ invoices: [FeeInvoice], current: Period) -> OverdueSummary? {
        let overdue = invoices.filter { $0.status == .due && $0.period < current }
        guard let latest = overdue.map(\.period).max() else { return nil }
        return OverdueSummary(
            amount: overdue.map(\.amount).total,
            parents: Set(overdue.map(\.studentID)).count,
            latest: latest,
            months: Set(overdue.map(\.period)).count
        )
    }
}
