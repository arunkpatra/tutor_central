import Foundation

/// What a young student's can-now-do says (P10-CanNowDo; plan/phase-14-plan.md decision 3), from the ladder: the steps
/// made secure this week, what the student can now do, one thing to do at home (a fixed line, no AI) and what is next.
public struct CanDoFacts: Hashable, Sendable {
    public struct MovedUp: Hashable, Sendable {
        public let area: Ladder.Area
        public let step: String

        public init(area: Ladder.Area, step: String) {
            self.area = area
            self.step = step
        }
    }

    public let movedUp: [MovedUp]
    public let canDo: [String]
    public let atHome: String
    public let next: [String]

    /// "Sentences · moved up this week"; "No change this week".
    public var movedUpLine: String {
        movedUp.first.map { "\($0.step) · moved up this week" } ?? "No change this week"
    }

    public var rows: [NoteContent.FactRow] {
        [
            .init(label: "Can now do", fact: Self.joined(canDo), symbol: "star"),
            .init(label: "At home", fact: atHome, symbol: "house"),
            .init(label: "Next", fact: next.isEmpty ? "Nothing set" : Self.joined(next), symbol: "arrow.right.circle"),
        ]
    }

    /// "Read short sentences · write letters · count to 99".
    static func joined(_ items: [String]) -> String {
        items.enumerated().map { $0 == 0 ? $1 : NoteWeek.lowered($1) }.joined(separator: " · ")
    }
}

public enum CanDoWeek {
    public static func facts(chapters: [Chapter], skills: [Skill], week: ClosedRange<Day>, calendar: Calendar)
        -> CanDoFacts {
        var movedUp: [CanDoFacts.MovedUp] = []
        var canDo: [String] = []
        var next: [String] = []
        var home: (area: Ladder.Area, step: Int)?
        for chapter in chapters.sorted(by: { $0.position < $1.position }) {
            guard let area = chapter.ladder else { continue }
            let steps = skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
            let current = Ladder.currentStep(steps.map(\.state)) ?? steps.count
            if current > 0, current - 1 < area.steps.count {
                canDo.append(Words.can[area]?[current - 1] ?? area.steps[current - 1])
                let made = steps[current - 1]
                if made.state == .secure, week.contains(Day(made.stateAt, calendar: calendar)) {
                    movedUp.append(.init(area: area, step: area.steps[current - 1]))
                    home = home ?? (area, current - 1)
                }
            }
            if current < area.steps.count {
                next.append(Words.next[area]?[current] ?? area.steps[current])
            }
            if home == nil, area == .reading {
                home = (area, max(0, min(current, area.steps.count) - 1))
            }
        }
        let fallback = movedUp.first.map { _ in home } ?? home
        let line = fallback.map { atHome(area: $0.area, step: $0.step) } ?? atHome(area: .reading, step: 0)
        return CanDoFacts(movedUp: movedUp, canDo: Array(canDo.prefix(4)), atHome: line, next: Array(next.prefix(3)))
    }

    /// The fixed line per area and step (the step just made secure, else reading's).
    public static func atHome(area: Ladder.Area, step: Int) -> String {
        let lines = Words.home[area] ?? []
        return lines[max(0, min(step, lines.count - 1))]
    }

    /// LKG and UKG, and classes 1 to 3 with a ladder chapter, get can-now-do; the rest the weekly note.
    public static func isLadderNote(_ student: Student, chapters: [Chapter]) -> Bool {
        switch student.classLevel {
        case .lkg, .ukg: true
        case .one, .two, .three: chapters.contains { $0.ladder != nil }
        default: false
        }
    }

    private enum Words {
        static let can: [Ladder.Area: [String]] = [
            .reading: [
                "Know the letters",
                "Read words",
                "Read short sentences",
                "Read a paragraph",
                "Read a short story",
            ],
            .writing: ["Trace letters", "Write letters", "Write words", "Write short sentences", "Write a few lines"],
            .numbers: ["Count to 9", "Count to 99", "Add to 20", "Take away within 20", "Multiply small numbers"],
        ]
        static let next: [Ladder.Area: [String]] = [
            .reading: [
                "Reading letters",
                "Reading words",
                "Reading sentences",
                "Reading a paragraph",
                "Reading a story",
            ],
            .writing: [
                "Tracing letters",
                "Writing letters",
                "Writing words",
                "Writing sentences",
                "Writing a few lines",
            ],
            .numbers: ["Counting to 9", "Counting to 99", "Adding to 20", "Taking away within 20", "Multiplying"],
        ]
        static let home: [Ladder.Area: [String]] = [
            .reading: [
                "Point to the letters in the picture book", "Five words a day from the picture book",
                "One page a day from the picture book", "One page a day, read aloud",
                "One short story a week, read aloud",
            ],
            .writing: [
                "Trace five letters a day", "Five letters a day in the notebook", "Five words a day in the notebook",
                "Two sentences a day in the notebook", "A few lines a day in the notebook",
            ],
            .numbers: [
                "Count things at home to 9", "Count things at home to 99", "Add small numbers with things at home",
                "Take away with things at home", "Say a times table aloud",
            ],
        ]
    }
}
