/// An Indian mobile number (D2): ten digits starting 6 to 9, stored E.164 (+91…), shown "+91 98765 43210".
public struct PhoneNumber: Hashable, Sendable {
    public let nationalDigits: String
    public static let invalidMessage = "Needs 10 digits after +91."

    /// From what the tutor typed: spaces, dashes, a leading 0, +91, 91 or 0091 are all fine.
    public init?(indianDigits typed: String) {
        var digits = typed.filter(\.isNumber)
        if digits.hasPrefix("0091") {
            digits.removeFirst(4)
        } else if digits.hasPrefix("91"), digits.count == 12 {
            digits.removeFirst(2)
        } else if digits.hasPrefix("0"), digits.count == 11 {
            digits.removeFirst()
        }
        guard digits.count == 10, let first = digits.first, "6789".contains(first),
              typed.allSatisfy({ $0.isNumber || " -+()".contains($0) }) else { return nil }
        nationalDigits = digits
    }

    public init?(e164: String) {
        guard e164.hasPrefix("+91") else { return nil }
        self.init(indianDigits: String(e164.dropFirst(3)))
    }

    public var e164: String {
        "+91\(nationalDigits)"
    }

    public var display: String {
        "+91 \(nationalDigits.prefix(5)) \(nationalDigits.dropFirst(5))"
    }
}
