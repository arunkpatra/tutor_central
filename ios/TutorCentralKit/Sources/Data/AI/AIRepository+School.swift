import Domain
import Foundation

/// What the school sent, as the app sends it to `/ai/parse-school`: the message's text or one reduced photo.
public enum SchoolSource: Hashable, Sendable {
    case text(String)
    case image(ImageUpload)
}

/// One item as read (the API's `ParsedItem`): the school's words; a date the message does not give is nil.
public struct ParsedItem: Hashable, Sendable, Decodable {
    public let kind: SchoolItemKind
    public let title: String
    public let subject: String?
    public let date: Day?
    public let endDate: Day?
    public let classLevel: ClassLevel?
    public let school: String?
    public let studentName: String?
    public let portions: String?

    public init(
        kind: SchoolItemKind, title: String, subject: String?, date: Day?, endDate: Day?, classLevel: ClassLevel?,
        school: String?, studentName: String?, portions: String?
    ) {
        self.kind = kind
        self.title = title
        self.subject = subject
        self.date = date
        self.endDate = endDate
        self.classLevel = classLevel
        self.school = school
        self.studentName = studentName
        self.portions = portions
    }

    private enum Keys: String, CodingKey {
        case kind, title, subject, date, endDate, classLevel, school, studentName, portions
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        kind = try c.decode(SchoolItemKind.self, forKey: .kind)
        title = try c.decode(String.self, forKey: .title)
        subject = try c.decodeIfPresent(String.self, forKey: .subject)
        date = try c.decodeIfPresent(String.self, forKey: .date).flatMap(Day.init(iso:))
        endDate = try c.decodeIfPresent(String.self, forKey: .endDate).flatMap(Day.init(iso:))
        classLevel = try c.decodeIfPresent(String.self, forKey: .classLevel).flatMap(ClassLevel.init(rawValue:))
        school = try c.decodeIfPresent(String.self, forKey: .school)
        studentName = try c.decodeIfPresent(String.self, forKey: .studentName)
        portions = try c.decodeIfPresent(String.self, forKey: .portions)
    }
}

/// What `/ai/parse-school` read, with the call's id.
public struct SchoolReading: Hashable, Sendable {
    public let id: UUID
    public let items: [ParsedItem]

    public init(id: UUID, items: [ParsedItem]) {
        self.id = id
        self.items = items
    }
}

/// `/ai/make` kind `mock`: portions and a pattern, no student (D62).
public struct MockRequest: Hashable, Sendable {
    public let classLevel: ClassLevel
    public let subject: String
    public let title: String
    public let portions: [String]
    public let pattern: MockPattern
    /// Kept in the mock's content (the exam it serves); not sent.
    public let schoolItemID: UUID?

    public init(
        classLevel: ClassLevel, subject: String, title: String, portions: [String], pattern: MockPattern,
        schoolItemID: UUID? = nil
    ) {
        self.classLevel = classLevel
        self.subject = subject
        self.title = title
        self.portions = portions
        self.pattern = pattern
        self.schoolItemID = schoolItemID
    }
}

public struct MadeMock: Hashable, Sendable {
    public let generationID: UUID
    public let content: MockContent

    public init(generationID: UUID, content: MockContent) {
        self.generationID = generationID
        self.content = content
    }
}

/// `/ai/make` kind `gap_report`: the student (their consent), the tallies, the days left.
public struct GapRequest: Hashable, Sendable {
    public let studentID: UUID
    public let classLevel: ClassLevel
    public let subject: String
    public let daysLeft: Int
    public let bySkill: [GapReportContent.Tally]

    public init(
        studentID: UUID,
        classLevel: ClassLevel,
        subject: String,
        daysLeft: Int,
        bySkill: [GapReportContent.Tally]
    ) {
        self.studentID = studentID
        self.classLevel = classLevel
        self.subject = subject
        self.daysLeft = daysLeft
        self.bySkill = bySkill
    }
}

public struct MadeGapReport: Hashable, Sendable {
    public let generationID: UUID
    public let summary: String
    public let days: [GapReportContent.DayPlan]

    public init(generationID: UUID, summary: String, days: [GapReportContent.DayPlan]) {
        self.generationID = generationID
        self.summary = summary
        self.days = days
    }
}

/// `/ai/make` kind `test_tomorrow`: the message in the parent's language (their student's consent).
public struct TestTomorrowRequest: Hashable, Sendable {
    public let studentID: UUID
    public let studentName: String
    public let parentName: String?
    public let tutorName: String
    public let centreName: String
    public let language: MessageLanguage
    public let subject: String
    public let title: String
    public let date: Day
    public let portions: String?
    public let revise: String?

    public init(
        studentID: UUID, studentName: String, parentName: String?, tutorName: String, centreName: String,
        language: MessageLanguage, subject: String, title: String, date: Day, portions: String?, revise: String?
    ) {
        self.studentID = studentID
        self.studentName = studentName
        self.parentName = parentName
        self.tutorName = tutorName
        self.centreName = centreName
        self.language = language
        self.subject = subject
        self.title = title
        self.date = date
        self.portions = portions
        self.revise = revise
    }
}

public struct MadeMessage: Hashable, Sendable {
    public let generationID: UUID
    public let message: String
    public let english: String

    public init(generationID: UUID, message: String, english: String) {
        self.generationID = generationID
        self.message = message
        self.english = english
    }
}

public extension AIRepository {
    /// V1's marking with no student named (a typed scheme or a paper): the centre's consent stands.
    func checkPaper(
        pages: [ImageUpload], scheme: SchemeSource, studentName: String, centre: UUID
    ) async throws(APIFailure) -> CheckAnswer {
        try await checkPaper(pages: pages, scheme: scheme, studentName: studentName, studentID: nil, centre: centre)
    }
}
