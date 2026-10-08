import Foundation

/// The UPI id as the tutor types it, held to the column's rule (migration 0001: `^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$`).
public enum UPIID {
    public static let invalidMessage = "A UPI id looks like name@bank."

    public static func normalised(_ typed: String) -> String? {
        let id = typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = id.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count >= 2, parts[1].count >= 2,
              parts[0].allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "._-".contains($0)) }),
              parts[1].allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        return id
    }
}

/// A UPI QR's payload: `upi://pay?pa=<payee>&pn=…` (NPCI's deep link). Only the payee is read.
public enum UPIQR {
    public static let notUPIMessage = "That QR is not a UPI QR."

    public static func upiID(in payload: String) -> String? {
        guard let components = URLComponents(string: payload.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "upi", components.host?.lowercased() == "pay",
              let payee = components.queryItems?.first(where: { $0.name.lowercased() == "pa" })?.value
        else { return nil }
        return UPIID.normalised(payee)
    }
}
