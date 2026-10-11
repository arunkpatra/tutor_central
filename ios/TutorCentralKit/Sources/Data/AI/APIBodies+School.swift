import Domain
import Foundation

/// POST /ai/parse-school: the message or one photo, today's date, the centre's schools and classes; no student.
struct ParseSchoolBody: Encodable {
    let centreId: String
    let text: String?
    let image: ImageBody?
    let today: String
    let schools: [String]
    let classLevels: [String]

    init(source: SchoolSource, today: Day, schools: [String], classLevels: [ClassLevel], centre: UUID) {
        centreId = centre.uuidString.lowercased()
        switch source {
        case let .text(words):
            text = words
            image = nil
        case let .image(upload):
            text = nil
            image = ImageBody(upload)
        }
        self.today = today.iso
        self.schools = schools
        self.classLevels = classLevels.map(\.rawValue)
    }
}

/// POST /ai/make with kind `mock`: strict on the API, so nothing but these keys.
struct MakeMockBody: Encodable {
    let kind = "mock"
    let centreId: String
    let classLevel: String
    let subject: String
    let title: String
    let portions: [String]
    let pattern: MockPattern

    init(_ request: MockRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        classLevel = request.classLevel.rawValue
        subject = request.subject
        title = request.title
        portions = request.portions
        pattern = request.pattern
    }
}

/// POST /ai/make with kind `gap_report`.
struct MakeGapBody: Encodable {
    let kind = "gap_report"
    let centreId: String
    let studentId: String
    let classLevel: String
    let subject: String
    let daysLeft: Int
    let bySkill: [GapReportContent.Tally]

    init(_ request: GapRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        classLevel = request.classLevel.rawValue
        subject = request.subject
        daysLeft = min(Self.maxDays, max(1, request.daysLeft))
        bySkill = Self.weakest(request.bySkill)
    }

    /// The API's limits (`/ai/make` kind `gap_report`): three days, twelve skills, a note of 300.
    static let maxDays = 3
    static let maxSkills = 12
    static let noteLimit = 300

    /// The twelve weakest skills (lowest share first, ties in the mock's order), sent in the mock's order with their
    /// notes cut to the limit; the report kept with the exam holds every skill.
    static func weakest(_ tallies: [GapReportContent.Tally]) -> [GapReportContent.Tally] {
        let share = { (tally: GapReportContent.Tally) in Double(tally.right) / Double(max(tally.of, 1)) }
        let kept = Set(
            tallies.enumerated()
                .sorted {
                    share($0.element) != share($1.element) ? share($0.element) < share($1.element) : $0.offset < $1
                        .offset
                }
                .prefix(maxSkills).map(\.offset)
        )
        return tallies.enumerated().filter { kept.contains($0.offset) }.map { _, tally in
            GapReportContent.Tally(
                skill: tally.skill, right: tally.right, of: tally.of,
                note: tally.note.map { String(String.UnicodeScalarView($0.unicodeScalars.prefix(noteLimit))) }
            )
        }
    }
}

/// POST /ai/make with kind `test_tomorrow`.
struct MakeTestTomorrowBody: Encodable {
    let kind = "test_tomorrow"
    let centreId: String
    let studentId: String
    let studentName: String
    let tutorName: String
    let centreName: String
    let parentName: String?
    let language: String
    let subject: String
    let title: String
    let date: String
    let portions: String?
    let revise: String?

    init(_ request: TestTomorrowRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        studentName = request.studentName
        tutorName = request.tutorName
        centreName = request.centreName
        parentName = request.parentName
        language = request.language.rawValue
        subject = request.subject
        title = request.title
        date = request.date.iso
        portions = request.portions.map { String($0.prefix(500)) }
        revise = request.revise
    }
}

struct ParseSchoolResult: Decodable {
    let items: [ParsedItem]
}

struct MockResult: Decodable {
    let title: String
    let durationMinutes: Int
    let sections: [MockContent.Section]
}

struct GapResult: Decodable {
    let summary: String
    let days: [GapReportContent.DayPlan]
}

struct MessageResult: Decodable {
    let message: String
    let english: String
}
