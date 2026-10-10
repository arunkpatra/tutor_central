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
    /// The kind a 429 was for: a V2 kind is the monthly allowance.
    let kind: String?

    init(error: String, reason: String?, limit: Int?, kind: String? = nil) {
        self.error = error
        self.reason = reason
        self.limit = limit
        self.kind = kind
    }
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

/// POST /ai/parse-textbook (api/src/schemas.ts `ParseTextbookInput`).
struct TextbookBody: Encodable {
    let centreId: String
    let image: ImageBody
    let classLevel: String
    let subject: String
}

/// POST /ai/make with kind `check`.
struct MakeCheckBody: Encodable {
    let kind = "check"
    let centreId: String
    let classLevel: String
    let subject: String
    let skills: [String]
}

/// POST /ai/make with kind `placement`.
struct MakePlacementBody: Encodable {
    let kind = "placement"
    let centreId: String
    let classLevel: String
    let subject: String
    let chapters: [String]
}

/// `{ id, result: { title, chapters } }`.
struct TextbookEnvelope: Decodable {
    struct Result: Decodable {
        let title: String?
        let chapters: [ReadChapter]
    }

    let id: UUID
    let result: Result
}

/// A chapter as the contents page read it, before it is numbered.
struct ReadChapter: Decodable {
    let name: String
    let skills: [String]
}

/// `{ id, result: { questions } }` for a check.
struct ChecksEnvelope: Decodable {
    struct Result: Decodable {
        let questions: [CheckQuestion]
    }

    let id: UUID
    let result: Result
}

/// `{ id, result: { questions } }` for a placement.
struct PlacementEnvelope: Decodable {
    struct Result: Decodable {
        let questions: [PlacementQuestion]
    }

    let id: UUID
    let result: Result
}

/// POST /ai/make with kind `sheet` (P10-Sheet): group material, no student.
struct MakeSheetBody: Encodable {
    let kind = "sheet"
    let centreId: String
    let classLevel: String
    let subject: String
    let skills: [String]
    let questions: Int
    let forHomework: Bool
    let reason: String?
}

/// POST /ai/make with kind `worked_example`.
struct MakeWorkedExampleBody: Encodable {
    let kind = "worked_example"
    let centreId: String
    let classLevel: String
    let subject: String
    let skill: String
}

/// POST /ai/make with kind `figure`: `figure` names the template.
struct MakeFigureBody: Encodable {
    let kind = "figure"
    let centreId: String
    let figure: String
    let classLevel: String
    let subject: String
    let skill: String
}

/// POST /ai/make with kind `brief`.
struct MakeBriefBody: Encodable {
    let kind = "brief"
    let centreId: String
    let classLevel: String
    let subject: String
    let chapter: String
}

/// POST /ai/plan: the groups to name, by class and subject.
struct PlanBody: Encodable {
    struct Group: Encodable {
        let groupNo: Int
        let classLevel: String
        let subject: String
    }

    let centreId: String
    let classId: String?
    let date: String
    let month: Int
    let groups: [Group]

    /// `classId` is sent as null when there is no batch, as the schema reads it.
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(centreId, forKey: .centreId)
        try container.encode(classId, forKey: .classId)
        try container.encode(date, forKey: .date)
        try container.encode(month, forKey: .month)
        try container.encode(groups, forKey: .groups)
    }

    private enum Keys: String, CodingKey { case centreId, classId, date, month, groups }
}

/// `{ id, result }` for a kind whose result decodes as `Result`.
struct MadeEnvelope<Result: Decodable>: Decodable {
    let id: UUID
    let result: Result
}

/// A sheet as the API answers it (a question set); the app adds its use.
struct SheetResult: Decodable {
    let title: String
    let instructions: String?
    let questions: [SheetQuestion]
}

struct TopicsResult: Decodable {
    let groups: [PlanTopic]
}
