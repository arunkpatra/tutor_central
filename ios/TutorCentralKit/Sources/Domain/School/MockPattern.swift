import Foundation

/// The mock's pattern (plan/phase-13-plan.md decision 12): the board's blueprint for class 10 (`syllabi.blueprint`),
/// else a default by class; the model chooses the sections within the marks when none are given.
public struct MockPattern: Hashable, Sendable, Codable {
    public struct Section: Hashable, Sendable, Codable {
        public let name: String
        public let questions: Int
        public let marksEach: Int

        public init(name: String, questions: Int, marksEach: Int) {
            self.name = name
            self.questions = questions
            self.marksEach = marksEach
        }
    }

    public let marks: Int
    public let durationMinutes: Int
    public let sections: [Section]?

    public init(marks: Int, durationMinutes: Int, sections: [Section]? = nil) {
        self.marks = marks
        self.durationMinutes = durationMinutes
        self.sections = sections
    }

    /// LKG to 5: 20 marks in 30 minutes; 6 and 7: 25 in 40; 8 and 9: 40 in 60; class 10, or no class: 80 in 180.
    public static func `default`(for level: ClassLevel?) -> MockPattern {
        switch level {
        case .lkg, .ukg, .one, .two, .three, .four, .five: MockPattern(marks: 20, durationMinutes: 30)
        case .six, .seven: MockPattern(marks: 25, durationMinutes: 40)
        case .eight, .nine: MockPattern(marks: 40, durationMinutes: 60)
        case .ten, nil: MockPattern(marks: 80, durationMinutes: 180)
        }
    }

    /// The syllabus data's blueprint as a pattern; nil for none or one that does not hold marks and minutes.
    public static func blueprint(_ json: Data) -> MockPattern? {
        guard let pattern = try? JSONDecoder().decode(MockPattern.self, from: json),
              pattern.marks > 0, pattern.durationMinutes > 0 else { return nil }
        return pattern
    }

    /// "25 marks · 40 minutes".
    public var line: String {
        "\(marks) marks · \(durationMinutes) minutes"
    }
}
