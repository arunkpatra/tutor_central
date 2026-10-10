/// The consent ask the tutor sends on WhatsApp (P10-Consent-Ask; `components.md` "The consent message"), signed as the
/// absence alert is.
public enum ConsentMessage {
    public static func text(
        parentFirstName: String, childFirstName: String, gender: Gender?, tutorName: String, centreName: String?
    ) -> String {
        let pronoun = switch gender {
        case .female: "her"
        case .male: "his"
        case .other, nil: "their"
        }
        let body = [
            "Hello \(parentFirstName), I use Tutor Central to plan \(childFirstName)'s classes and keep",
            "\(pronoun) progress. To prepare \(pronoun) practice sheets and your weekly note, \(pronoun) name, class,",
            "marks and work may be read by an AI service (Claude, by Anthropic). It keeps nothing for training and",
            "deletes what it reads within 30 days. Please reply YES if you agree. Thank you.",
        ].joined(separator: " ")
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        return "\(body)\n\n\(signature)"
    }
}
