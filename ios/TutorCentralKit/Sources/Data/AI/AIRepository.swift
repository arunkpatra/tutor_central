import Domain
import Foundation

/// A photo as the app sends it: already reduced on the device (`PhotoReducer`), never stored anywhere.
public struct ImageUpload: Hashable, Sendable {
    public let data: Data
    /// "image/jpeg", "image/png" or "image/webp".
    public let mediaType: String

    public init(data: Data, mediaType: String) {
        self.data = data
        self.mediaType = mediaType
    }

    public var base64: String {
        data.base64EncodedString()
    }
}

/// What a generation needs beyond the form: the names the register knows. The API records the class's and the
/// student's ids too, so a result read back later names them again.
public struct GenerateContext: Hashable, Sendable {
    public let centre: UUID
    public let className: String?
    public let subject: String
    public let studentName: String?
    public let parentName: String?
    public let attendanceLine: String?
    public let tutorName: String
    public let centreName: String

    public init(
        centre: UUID, className: String?, subject: String, studentName: String?, parentName: String?,
        attendanceLine: String?, tutorName: String, centreName: String
    ) {
        self.centre = centre
        self.className = className
        self.subject = subject
        self.studentName = studentName
        self.parentName = parentName
        self.attendanceLine = attendanceLine
        self.tutorName = tutorName
        self.centreName = centreName
    }
}

/// A register row as the API read it: the phone already E.164 or nil, the fee whole rupees or nil.
public struct ScanRowDTO: Decodable, Hashable, Sendable {
    public let name: String
    public let phone: String?
    public let fee: Int?

    public init(name: String, phone: String?, fee: Int?) {
        self.name = name
        self.phone = phone
        self.fee = fee
    }
}

/// The marks as the API returned them; `result` clamps any mark over its question's.
public struct CheckResultDTO: Decodable, Hashable, Sendable {
    public struct Question: Decodable, Hashable, Sendable {
        public let number: Int
        public let text: String
        public let note: String
        public let marks: Int
        public let of: Int
    }

    public let questions: [Question]
    public let summary: String

    public var result: CheckResult {
        CheckResult.clamped(CheckResult(
            questions: questions.map {
                .init(number: $0.number, text: $0.text, note: $0.note, marks: $0.marks, of: $0.of, changedFrom: nil)
            },
            summary: summary
        ))
    }
}

/// The scanned rows and the record's id.
public struct ScanAnswer: Hashable, Sendable {
    public let id: UUID
    public let rows: [ScanRowDTO]

    public init(id: UUID, rows: [ScanRowDTO]) {
        self.id = id
        self.rows = rows
    }
}

/// The suggested marks and the record's id.
public struct CheckAnswer: Hashable, Sendable {
    public let id: UUID
    public let result: CheckResult

    public init(id: UUID, result: CheckResult) {
        self.id = id
        self.result = result
    }
}

/// A contents page read (POST /ai/parse-textbook): the chapters numbered in the book's order. Nothing of the photo.
public struct TextbookReading: Hashable, Sendable {
    public let id: UUID
    public let title: String?
    public let chapters: [TextbookChapter]

    public init(id: UUID, title: String?, chapters: [TextbookChapter]) {
        self.id = id
        self.title = title
        self.chapters = chapters
    }
}

/// One of the close's questions: the skill as asked for, the question, the answer for the tutor's eye.
public struct CheckQuestion: Hashable, Sendable, Codable {
    public let skill: String
    public let question: String
    public let answer: String

    public init(skill: String, question: String, answer: String) {
        self.skill = skill
        self.question = question
        self.answer = answer
    }
}

/// One of the placement's questions: the chapter (or ladder step) as asked for.
public struct PlacementQuestion: Hashable, Sendable, Codable {
    public let chapter: String
    public let question: String
    public let answer: String

    public init(chapter: String, question: String, answer: String) {
        self.chapter = chapter
        self.question = question
        self.answer = answer
    }
}

/// Our API's AI routes (api/src/routes/ai.ts, v2.ts). Never Anthropic directly: the app holds no AI key (D11).
public protocol AIRepository: Sendable {
    /// POST /ai/generate: the kind's result and the generation's id.
    func generate(_ request: GenerateRequest, context: GenerateContext) async throws(APIFailure) -> Generation
    /// POST /ai/scan-register.
    func scanRegister(_ image: ImageUpload, centre: UUID) async throws(APIFailure) -> ScanAnswer
    /// POST /ai/check-paper: the pages in order and the scheme.
    func checkPaper(
        pages: [ImageUpload], scheme: SchemeSource, studentName: String, centre: UUID
    ) async throws(APIFailure) -> CheckAnswer
    /// POST /ai/parse-textbook: one contents page read into chapters and skills (the photo is not kept anywhere).
    func parseTextbook(
        _ image: ImageUpload, classLevel: ClassLevel, subject: String, centre: UUID
    ) async throws(APIFailure) -> TextbookReading
    /// POST /ai/make, kind `check`: one question per skill (one to three), for the close.
    func makeChecks(
        classLevel: ClassLevel, subject: String, skills: [String], centre: UUID
    ) async throws(APIFailure) -> [CheckQuestion]
    /// POST /ai/make, kind `placement`: one question per chapter or ladder step.
    func makePlacement(
        classLevel: ClassLevel, subject: String, chapters: [String], centre: UUID
    ) async throws(APIFailure) -> [PlacementQuestion]
}
