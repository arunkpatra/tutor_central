import Foundation

/// Where a homework given at a close stands (`homework_status`, migration 0010). A row starts as given; the tutor taps
/// Done, Partial or Not done on the student's page (plan decision 15).
public enum HomeworkStatus: String, CaseIterable, Hashable, Sendable, Codable {
    case given, done, partial, notDone = "not_done"

    public var title: String {
        switch self {
        case .given: "Given"
        case .done: "Done"
        case .partial: "Partial"
        case .notDone: "Not done"
        }
    }
}

/// One check as read back (`checks`): a question tapped right or wrong at a close, or one of the placement's.
public struct CheckRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let studentID: UUID
    public let skillID: UUID
    public let sessionID: UUID?
    public let question: String
    public let correct: Bool
    public let at: Date
    public let isPlacement: Bool

    public init(
        id: UUID, studentID: UUID, skillID: UUID, sessionID: UUID?, question: String, correct: Bool, at: Date,
        isPlacement: Bool
    ) {
        self.id = id
        self.studentID = studentID
        self.skillID = skillID
        self.sessionID = sessionID
        self.question = question
        self.correct = correct
        self.at = at
        self.isPlacement = isPlacement
    }
}

/// One homework given at a close (`homework`).
public struct HomeworkRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let studentID: UUID
    public let sessionID: UUID
    public let givenAt: Date
    public var status: HomeworkStatus

    public init(id: UUID, studentID: UUID, sessionID: UUID, givenAt: Date, status: HomeworkStatus) {
        self.id = id
        self.studentID = studentID
        self.sessionID = sessionID
        self.givenAt = givenAt
        self.status = status
    }
}

/// A skill's new state, worked out by the app and written by the close or the placement (migration 0017).
public struct SkillStateChange: Hashable, Sendable, Codable {
    public let skillID: UUID
    public let state: SkillState

    public init(skillID: UUID, state: SkillState) {
        self.skillID = skillID
        self.state = state
    }
}

/// What a message to a parent was about (`message_kind`, migrations 0001 and 0011).
public enum MessageKind: String, CaseIterable, Hashable, Sendable, Codable {
    case reminder, receipt, absence, progress, note
    case canDo = "can_do", testTomorrow = "test_tomorrow"
    case homework, consent

    public var title: String {
        switch self {
        case .reminder: "Fee reminder"
        case .receipt: "Receipt"
        case .absence: "Absence alert"
        case .progress: "Progress note"
        case .note: "Weekly note"
        case .canDo: "Can now do"
        case .testTomorrow: "Test tomorrow"
        case .homework: "Homework"
        case .consent: "Consent"
        }
    }
}

/// One message sent about a student (`message_log`), as the page's Messages section lists it.
public struct MessageEntry: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let kind: MessageKind
    public let openedAt: Date
    public let language: MessageLanguage?

    public init(id: UUID, kind: MessageKind, openedAt: Date, language: MessageLanguage?) {
        self.id = id
        self.kind = kind
        self.openedAt = openedAt
        self.language = language
    }
}
