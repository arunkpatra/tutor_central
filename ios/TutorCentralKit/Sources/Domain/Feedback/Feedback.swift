import Foundation

/// What a tutor did with a made thing (D107, `generation_feedback`): edited a note before sending it, asked for it
/// again
/// with a reason, or put their own in its place.
public enum FeedbackKind: String, Hashable, Sendable {
    case edit, again, replace
}

/// What took the made thing's place: the text sent or typed, or a photo (never the photo itself).
public enum FeedbackRevision: Hashable, Sendable {
    case text(String)
    case photo

    public var text: String? {
        if case let .text(text) = self {
            return text
        }
        return nil
    }
}

/// One feedback row on the generation it is about: a reason for `again` (200 scalars at most), what replaced it for
/// `edit` and `replace`.
public struct Feedback: Hashable, Sendable {
    public let generation: UUID
    public let kind: FeedbackKind
    public let reason: String?
    public let revised: FeedbackRevision?

    public init(generation: UUID, kind: FeedbackKind, reason: String?, revised: FeedbackRevision?) {
        self.generation = generation
        self.kind = kind
        self.reason = reason
        self.revised = revised
    }

    public static func edit(_ generation: UUID, sent: String) -> Feedback {
        Feedback(generation: generation, kind: .edit, reason: nil, revised: .text(sent))
    }

    public static func again(_ generation: UUID, reason: String) -> Feedback {
        Feedback(
            generation: generation,
            kind: .again,
            reason: String(reason.prefix(RegenerateReason.ownLimit)),
            revised: nil
        )
    }

    public static func replace(_ generation: UUID, with revised: FeedbackRevision) -> Feedback {
        Feedback(generation: generation, kind: .replace, reason: nil, revised: revised)
    }
}
