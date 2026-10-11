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
    let artefactId: UUID?

    var record: HomeworkRecord {
        HomeworkRecord(
            id: id, studentID: studentId, sessionID: sessionId, givenAt: givenAt, status: status,
            artefactID: artefactId
        )
    }
}

/// A `message_log` row as the page's Messages section reads it; nil for a kind this build does not know.
struct MessageEntryRow: Decodable {
    let id: UUID
    let kind: String
    let openedAt: Date
    let language: String?
    /// Absent from a row read before Phase 14's columns were selected: WhatsApp, no body.
    let channel: String?
    let body: String?

    var entry: MessageEntry? {
        MessageKind(rawValue: kind).map {
            MessageEntry(
                id: id, kind: $0, openedAt: openedAt, language: language.flatMap(MessageLanguage.init),
                channel: channel.flatMap(MessageChannel.init) ?? .whatsAppLink, body: body
            )
        }
    }
}

/// A `marks` row (migrations 0011 and 0021). The score and max are numeric; the questions are the API's marking, or
/// anything else the row holds, which reads as none.
struct MarkRow: Decodable {
    let id: UUID
    let studentId: UUID
    let subject: String
    let test: String
    let date: String
    let score: Double
    let max: Double
    let photoPath: String?
    let schoolItemId: UUID?
    let artefactId: UUID?
    let questions: [CheckResult.QuestionMark]?

    static let columns = "id, student_id, subject, test, date, score, max, photo_path, school_item_id, artefact_id, "
        + "questions"

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        studentId = try c.decode(UUID.self, forKey: .studentId)
        subject = try c.decode(String.self, forKey: .subject)
        test = try c.decode(String.self, forKey: .test)
        date = try c.decode(String.self, forKey: .date)
        score = try c.decode(Double.self, forKey: .score)
        max = try c.decode(Double.self, forKey: .max)
        photoPath = try c.decodeIfPresent(String.self, forKey: .photoPath)
        schoolItemId = try c.decodeIfPresent(UUID.self, forKey: .schoolItemId)
        artefactId = try c.decodeIfPresent(UUID.self, forKey: .artefactId)
        questions = try? c.decodeIfPresent([CheckResult.QuestionMark].self, forKey: .questions)
    }

    private enum CodingKeys: String, CodingKey {
        case id, studentId, subject, test, date, score, max, photoPath, schoolItemId, artefactId, questions
    }

    var record: MarkRecord? {
        guard let day = Day(iso: date) else { return nil }
        return MarkRecord(
            id: id, studentID: studentId, subject: subject, test: test, date: day, score: Int(score.rounded()),
            max: Int(max.rounded()), photoPath: photoPath, schoolItemID: schoolItemId, artefactID: artefactId,
            questions: questions
        )
    }
}
