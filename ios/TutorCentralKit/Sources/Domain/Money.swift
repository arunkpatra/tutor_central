import Foundation

/// Whole rupees. INR has no fractional fees in this product (D2).
public struct Money: Hashable, Sendable, Comparable, AdditiveArithmetic {
    public let rupees: Int

    public init(rupees: Int) {
        self.rupees = rupees
    }

    public static let zero = Money(rupees: 0)

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(rupees: lhs.rupees + rhs.rupees)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(rupees: lhs.rupees - rhs.rupees)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.rupees < rhs.rupees
    }

    /// "₹1,20,000": Indian grouping, no decimals.
    public var formatted: String {
        rupees.formatted(.currency(code: "INR").locale(Locale(identifier: "en_IN")).precision(.fractionLength(0)))
    }
}

public extension Sequence<Money> {
    var total: Money {
        reduce(.zero, +)
    }
}
