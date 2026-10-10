import Domain
import Foundation

/// A `checks` row. The question is kept as `{"text": …}`; an empty object reads as no words.
struct CheckRow: Decodable {
    struct Question: Decodable {
        let text: String?
    }

    let id: UUID
    let studentId: UUID
    let skillId: UUID
    let sessionId: UUID?
    let kind: String
    let question: Question?
    let correct: Bool
    let createdAt: Date

    var record: CheckRecord {
        CheckRecord(
            id: id, studentID: studentId, skillID: skillId, sessionID: sessionId, question: question?.text ?? "",
            correct: correct, at: createdAt, isPlacement: kind == "placement"
        )
    }
}

/// A `homework` row.
struct HomeworkRow: Decodable {
    let id: UUID
    let studentId: UUID
    let sessionId: UUID
    let givenAt: Date
    let status: HomeworkStatus

    var record: HomeworkRecord {
        HomeworkRecord(id: id, studentID: studentId, sessionID: sessionId, givenAt: givenAt, status: status)
    }
}

/// A `message_log` row as the page's Messages section reads it; nil for a kind this build does not know.
struct MessageEntryRow: Decodable {
    let id: UUID
    let kind: String
    let openedAt: Date
    let language: String?

    var entry: MessageEntry? {
        MessageKind(rawValue: kind).map {
            MessageEntry(id: id, kind: $0, openedAt: openedAt, language: language.flatMap(MessageLanguage.init))
        }
    }
}
