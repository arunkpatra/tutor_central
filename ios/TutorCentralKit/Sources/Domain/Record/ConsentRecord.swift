import Foundation

/// The parent's recorded agreement (D62): when, which number, how (`students.consent_at`, `consent_phone`,
/// `consent_how`).
public struct ConsentRecord: Hashable, Sendable, Codable {
    public let at: Date
    public let phone: PhoneNumber
    public let how: ConsentMethod

    public init(at: Date, phone: PhoneNumber, how: ConsentMethod) {
        self.at = at
        self.phone = phone
        self.how = how
    }
}
