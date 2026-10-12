import Foundation

/// How the parent agreed to the student's own data going to the AI (`students.consent_how`, D62).
public enum ConsentMethod: String, CaseIterable, Hashable, Sendable, Codable {
    case inPerson = "in_person", call, whatsapp

    public var title: String {
        switch self {
        case .inPerson: "In person"
        case .call: "On a call"
        case .whatsapp: "On WhatsApp"
        }
    }
}

/// One event of a student's consent history (`consent_events`, D79): agreed with the number and how, or withdrawn with
/// how; when. Read newest first.
public struct ConsentEvent: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable, Codable {
        case given, withdrawn
    }

    public let kind: Kind
    public let how: ConsentMethod?
    public let at: Date
    public let phone: PhoneNumber?

    public init(kind: Kind, how: ConsentMethod?, at: Date, phone: PhoneNumber?) {
        self.kind = kind
        self.how = how
        self.at = at
        self.phone = phone
    }
}
