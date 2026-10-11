import Foundation

/// A mock in the school's pattern (P10-Mock): the API's paper with each question's skill, and what the app adds (the
/// pattern asked for, the portions, the exam it serves).
public struct MockContent: Hashable, Sendable, Codable {
    public struct Question: Hashable, Sendable, Codable, Identifiable {
        public var id: Int {
            number
        }

        public let number: Int
        public let text: String
        public let marks: Int
        public let answer: String
        public let skill: String

        public init(number: Int, text: String, marks: Int, answer: String, skill: String) {
            self.number = number
            self.text = text
            self.marks = marks
            self.answer = answer
            self.skill = skill
        }
    }

    public struct Section: Hashable, Sendable, Codable, Identifiable {
        public var id: String {
            name
        }

        public let name: String
        public let marksEach: Int
        public let questions: [Question]

        public init(name: String, marksEach: Int, questions: [Question]) {
            self.name = name
            self.marksEach = marksEach
            self.questions = questions
        }
    }

    public let title: String
    public let durationMinutes: Int
    public let sections: [Section]
    public let pattern: MockPattern
    public let portions: [String]
    public let schoolItemID: UUID?

    public init(
        title: String, durationMinutes: Int, sections: [Section], pattern: MockPattern, portions: [String],
        schoolItemID: UUID?
    ) {
        self.title = title
        self.durationMinutes = durationMinutes
        self.sections = sections
        self.pattern = pattern
        self.portions = portions
        self.schoolItemID = schoolItemID
    }

    /// `schoolItemId`, so the snake-case strategy's `school_item_id` reads back.
    private enum CodingKeys: String, CodingKey {
        case title, durationMinutes, sections, pattern, portions
        case schoolItemID = "schoolItemId"
    }

    public var marks: Int {
        sections.flatMap(\.questions).reduce(0) { $0 + $1.marks }
    }

    /// "25 marks · 40 minutes · Chemical reactions and Acids, bases and salts".
    public var line: String {
        let head = "\(marks) marks · \(durationMinutes) minutes"
        return portions.isEmpty ? head : "\(head) · \(ListWords.and(portions))"
    }
}

/// What a marked mock showed and the last days' lines (P10-GapReport). The tallies are the app's arithmetic; the
/// summary and the days are the model's. `usedAt` is set by Use this plan.
public struct GapReportContent: Hashable, Sendable, Codable {
    public struct Tally: Hashable, Sendable, Codable, Identifiable {
        public var id: String {
            skill
        }

        public let skill: String
        public let right: Int
        public let of: Int
        public let note: String?

        public init(skill: String, right: Int, of: Int, note: String?) {
            self.skill = skill
            self.right = right
            self.of = of
            self.note = note
        }

        var share: Double {
            of > 0 ? Double(right) / Double(of) : 0
        }
    }

    public struct DayPlan: Hashable, Sendable, Codable {
        public let title: String
        public let line: String

        public init(title: String, line: String) {
            self.title = title
            self.line = line
        }
    }

    public let summary: String
    public let bySkill: [Tally]
    public let days: [DayPlan]
    public var usedAt: Date?
    public let score: Int
    public let max: Int
    public let schoolItemID: UUID

    public init(
        summary: String, bySkill: [Tally], days: [DayPlan], usedAt: Date?, score: Int, max: Int, schoolItemID: UUID
    ) {
        self.summary = summary
        self.bySkill = bySkill
        self.days = days
        self.usedAt = usedAt
        self.score = score
        self.max = max
        self.schoolItemID = schoolItemID
    }

    private enum CodingKeys: String, CodingKey {
        case summary, bySkill, days, usedAt, score, max
        case schoolItemID = "schoolItemId"
    }
}
