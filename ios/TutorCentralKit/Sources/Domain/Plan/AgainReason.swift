import Foundation

/// Make it again's or Write again's reason on the brief, the mock and the note (P21-Brief-Again, P21-Mock-Again,
/// P21-Note-Again; D107): the menu's rows, the words the prompt reads (and the feedback keeps), and the line under the
/// old one while the new one comes. The sheet keeps its own (`RegenerateReason`).
public protocol AgainReason: Hashable, Sendable {
    /// The menu's rows, in order, before "Say what to change…".
    static var menu: [Self] { get }
    /// The tutor's own words.
    static func own(_ words: String) -> Self
    /// The menu's label; also what the prompt reads for a row.
    var label: String { get }
    /// What the prompt reads: the label, or the tutor's words trimmed and cut to 200 scalars.
    var words: String { get }
    /// "A shorter brief is on its way. This one stays until it arrives."
    var line: String { get }
}

extension AgainReason {
    static func trimmed(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.prefix(RegenerateReason.ownLimit))
    }

    static func arriving(_ what: String) -> String {
        "\(what) is on its way. This one stays until it arrives."
    }
}

public enum BriefReason: AgainReason {
    case shorter, simplerWords, differentExample, moreOnMistakes, own(String)

    public static let menu: [BriefReason] = [.shorter, .simplerWords, .differentExample, .moreOnMistakes]

    public var label: String {
        switch self {
        case .shorter: "Shorter"
        case .simplerWords: "Simpler words"
        case .differentExample: "A different example"
        case .moreOnMistakes: "More on the mistakes"
        case let .own(words): Self.trimmed(words)
        }
    }

    public var words: String {
        label
    }

    public var line: String {
        let what = switch self {
        case .shorter: "A shorter brief"
        case .simplerWords: "A simpler brief"
        case .differentExample: "A brief with a different example"
        case .moreOnMistakes: "A brief with more on the mistakes"
        case .own: "A new brief"
        }
        return Self.arriving(what)
    }
}

public enum MockReason: AgainReason {
    case easier, harder, differentQuestions, closerToSchool, own(String)

    public static let menu: [MockReason] = [.easier, .harder, .differentQuestions, .closerToSchool]

    public var label: String {
        switch self {
        case .easier: "Easier"
        case .harder: "Harder"
        case .differentQuestions: "Different questions"
        case .closerToSchool: "Closer to the school's papers"
        case let .own(words): Self.trimmed(words)
        }
    }

    public var words: String {
        label
    }

    public var line: String {
        let what = switch self {
        case .easier: "An easier mock"
        case .harder: "A harder mock"
        case .differentQuestions: "A mock with different questions"
        case .closerToSchool: "A mock closer to the school's papers"
        case .own: "A new mock"
        }
        return Self.arriving(what)
    }
}

public enum NoteReason: AgainReason {
    case shorter, warmer, plainerWords, lessAboutMarks, own(String)

    public static let menu: [NoteReason] = [.shorter, .warmer, .plainerWords, .lessAboutMarks]

    public var label: String {
        switch self {
        case .shorter: "Shorter"
        case .warmer: "Warmer"
        case .plainerWords: "Plainer words"
        case .lessAboutMarks: "Less about marks"
        case let .own(words): Self.trimmed(words)
        }
    }

    public var words: String {
        label
    }

    public var line: String {
        let what = switch self {
        case .shorter: "A shorter note"
        case .warmer: "A warmer note"
        case .plainerWords: "A plainer note"
        case .lessAboutMarks: "A note with less about marks"
        case .own: "A fresh note"
        }
        return Self.arriving(what)
    }
}
