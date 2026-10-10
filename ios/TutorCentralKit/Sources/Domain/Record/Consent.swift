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
