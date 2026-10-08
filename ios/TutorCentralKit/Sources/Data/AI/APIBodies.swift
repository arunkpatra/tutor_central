import Domain
import Foundation

/// The bodies the API's schemas take (api/src/schemas.ts); a nil field is left out.
struct GenerateBody: Encodable {
    let kind: String
    let centreId: String
    let subject: String
    let classLevel: String
    var classId: String?
    var topic: String?
    var level: String?
    var questions: Int?
    var marks: Int?
    var withAnswers: Bool?
    var studentId: String?
    var studentName: String?
    var parentName: String?
    var observations: String?
    var attendanceLine: String?
    var tone: String?
    var tutorName: String?
    var centreName: String?

    init(_ request: GenerateRequest, context: GenerateContext) {
        kind = request.kind.rawValue
        centreId = context.centre.uuidString.lowercased()
        subject = context.subject
        classLevel = context.className ?? "No class"
        classId = request.classID?.uuidString.lowercased()
        switch request {
        case let .paper(form):
            topic = form.topic
            level = form.level.rawValue
            questions = form.questions
            marks = form.marks
        case let .homework(form):
            topic = form.topic
            level = form.level.rawValue
            questions = form.questions
        case let .worksheet(form):
            topic = form.topic
            level = form.level.rawValue
            questions = form.questions
            withAnswers = form.withAnswers
        case let .progressNote(form):
            studentId = form.studentID?.uuidString.lowercased()
            observations = form.observations
            tone = form.tone.rawValue
            studentName = context.studentName
            parentName = context.parentName
            attendanceLine = context.attendanceLine
            tutorName = context.tutorName
            centreName = context.centreName
        }
        topic = topic?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ImageBody: Encodable {
    let imageBase64: String
    let mediaType: String

    init(_ upload: ImageUpload) {
        imageBase64 = upload.base64
        mediaType = upload.mediaType
    }
}

struct ScanBody: Encodable {
    let centreId: String
    let imageBase64: String
    let mediaType: String
}

struct SchemeBody: Encodable {
    let kind: String
    var generationId: String?
    var text: String?

    init(_ source: SchemeSource) {
        switch source {
        case let .paper(id):
            kind = "paper"
            generationId = id.uuidString.lowercased()
        case let .typed(typed):
            kind = "typed"
            text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

struct CheckBody: Encodable {
    let centreId: String
    let pages: [ImageBody]
    let scheme: SchemeBody
    let studentName: String
}

/// `{ error, reason?, limit? }`: what the API says when it refuses.
struct ErrorBody: Decodable {
    let error: String
    let reason: String?
    let limit: Int?
}

/// `{ id, result }` with the result kept as raw JSON until its kind is known.
struct AnswerEnvelope: Decodable {
    let id: UUID
}

struct ScanEnvelope: Decodable {
    struct Rows: Decodable {
        let rows: [ScanRowDTO]
    }

    let id: UUID
    let result: Rows
}

struct CheckEnvelope: Decodable {
    let id: UUID
    let result: CheckResultDTO
}
