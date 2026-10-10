/// The language of the parent's messages (`students.message_language`); teaching material stays in English.
public enum MessageLanguage: String, CaseIterable, Hashable, Sendable, Codable {
    case english = "en", hinglish, hindi = "hi", kannada = "kn"

    public static let `default` = MessageLanguage.english

    public var title: String {
        switch self {
        case .english: "English"
        case .hinglish: "Hinglish"
        case .hindi: "Hindi"
        case .kannada: "Kannada"
        }
    }
}
