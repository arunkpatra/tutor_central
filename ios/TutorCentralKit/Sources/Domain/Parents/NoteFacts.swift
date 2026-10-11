import Foundation

/// What the weekly note says, worked out on the phone from the week's record (plan/phase-14-plan.md decision 2): the
/// model words these facts and nothing else; the note's "What it says" shows them.
public struct NoteFacts: Hashable, Sendable {
    /// Skill names taught this week, in chapter order, six at most.
    public let taught: [String]
    public let taughtLine: String
    /// "8 of 12 checks", "8 of 12 checks · 14 of 25 on Unit test 2"; nil with neither.
    public let right: String?
    public let practise: [String]
    /// The next skill or chapter, then the nearest exam ("the unit test on Fri 16 Oct").
    public let coming: [String]
    /// "absent 2 of 3 classes", "absent all week (3 classes)"; nil with no absence or no class.
    public let attendance: String?
    public let absentAllWeek: Bool
    let checksRight: Int
    let checksAsked: Int

    public var rightLine: String {
        right ?? "No checks yet"
    }

    public var practiseLine: String {
        practise.isEmpty ? "Nothing to add" : practise.joined(separator: " · ")
    }

    public var comingLine: String {
        coming.isEmpty ? "Nothing set" : coming.joined(separator: " · ")
    }

    /// "What it says" (P10-Note).
    public var rows: [NoteContent.FactRow] {
        [
            .init(label: "Taught", fact: taughtLine, symbol: "book.closed"),
            .init(label: "Got right", fact: rightLine, symbol: "checkmark.circle"),
            .init(label: "To practise", fact: practiseLine, symbol: "pencil.line"),
            .init(label: "Coming", fact: comingLine, symbol: "calendar"),
        ]
    }

    /// The Notes card's lead fact (P10-Today-NoteDay): "not on track", "2 absences", "absent Wed", "all right", else
    /// the
    /// first thing to practise.
    public func lead(status: TrackStatus, absentDays: [Day]) -> String {
        if status == .notOnTrack {
            return "not on track"
        }
        if absentDays.count >= 2 {
            return "\(absentDays.count) absences"
        }
        if let only = absentDays.first {
            return "absent \(only.shortWeekday)"
        }
        if checksAsked > 0, checksRight == checksAsked {
            return "all right"
        }
        return practise.first ?? ""
    }
}

/// A student's record as the note reads it: their book, checks, the batch's sessions, marks and the school's items.
public struct NoteRecord: Sendable {
    public let student: Student
    public let chapters: [Chapter]
    public let skills: [Skill]
    public let checks: [CheckRecord]
    public let sessions: [AttendanceSession]
    public let marks: [MarkRecord]
    public let items: [SchoolItem]

    public init(
        student: Student, chapters: [Chapter], skills: [Skill], checks: [CheckRecord], sessions: [AttendanceSession],
        marks: [MarkRecord], items: [SchoolItem]
    ) {
        self.student = student
        self.chapters = chapters
        self.skills = skills
        self.checks = checks
        self.sessions = sessions
        self.marks = marks
        self.items = items
    }
}

/// The week's facts for a student's note (pure).
public enum NoteWeek {
    public static let taughtLimit = 6
    public static let practiseLimit = 3

    public static func facts(_ record: NoteRecord, week: ClosedRange<Day>, calendar: Calendar) -> NoteFacts {
        let (student, skills) = (record.student, record.skills)
        let order = Order(chapters: record.chapters)
        let attended = record.sessions.filter { week.contains($0.date) && $0.marks[student.id] != nil }
        let absences = attended.filter { $0.marks[student.id] == .absent }.count
        let absentAllWeek = !attended.isEmpty && absences == attended.count
        let taught = absentAllWeek ? [] : order.sorted(skills.filter {
            $0.state != .notStarted && week.contains(Day($0.stateAt, calendar: calendar))
        }).prefix(taughtLimit).map(\.self)
        let weekChecks = record.checks.filter { !$0.isPlacement && week.contains(Day($0.at, calendar: calendar)) }
        let rightCount = weekChecks.filter(\.correct).count
        return NoteFacts(
            taught: taught.map(\.name),
            taughtLine: taughtLine(taught, order: order, absentAllWeek: absentAllWeek),
            right: rightWords(right: rightCount, asked: weekChecks.count, mark: weekMark(record.marks, week: week)),
            practise: practise(skills: skills, taught: taught, wrong: weekChecks.filter { !$0.correct }, order: order),
            coming: coming(record, order: order, week: week, calendar: calendar),
            attendance: attendanceWords(absences: absences, classes: attended.count),
            absentAllWeek: absentAllWeek,
            checksRight: rightCount,
            checksAsked: weekChecks.count
        )
    }

    /// The Notes card's topic: the first taught skill's chapter, else the current skill's.
    public static func topic(_ facts: NoteFacts, chapters: [Chapter], skills: [Skill]) -> String? {
        let byID = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        let first = facts.taught.first.flatMap { name in skills.first { $0.name == name } }
            ?? TrackingRules.currentSkill(skills: skills, chapters: chapters)
        return first.flatMap { byID[$0.chapterID]?.name }
    }

    /// "Chemical reactions: balancing equations, types of reactions · Acids, bases and salts: naming acids".
    private static func taughtLine(_ taught: [Skill], order: Order, absentAllWeek: Bool) -> String {
        if absentAllWeek {
            return "Nothing new this week: absent all week"
        }
        guard !taught.isEmpty else { return "Nothing new this week" }
        var runs: [(chapter: String, names: [String])] = []
        for skill in taught {
            let chapter = order.chapter(skill)?.name ?? ""
            if runs.last?.chapter == chapter {
                runs[runs.count - 1].names.append(lowered(skill.name))
            } else {
                runs.append((chapter, [lowered(skill.name)]))
            }
        }
        return runs
            .map {
                $0.chapter.isEmpty ? $0.names
                    .joined(separator: ", ") : "\($0.chapter): \($0.names.joined(separator: ", "))"
            }
            .joined(separator: " · ")
    }

    private static func weekMark(_ marks: [MarkRecord], week: ClosedRange<Day>) -> MarkRecord? {
        marks.filter { week.contains($0.date) }.max { $0.date < $1.date }
    }

    private static func rightWords(right: Int, asked: Int, mark: MarkRecord?) -> String? {
        let parts = [asked > 0 ? "\(right) of \(asked) checks" : nil, mark.map { "\($0.line) on \($0.test)" }]
            .compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Practising or revisit skills in the week's chapters (those taught, else the current skill's); else the skills
    /// the
    /// week's wrong checks were on.
    private static func practise(skills: [Skill], taught: [Skill], wrong: [CheckRecord], order: Order) -> [String] {
        let current = order.sorted(skills).first { $0.state != .secure }
        let chapters = Set(taught.isEmpty ? [current?.chapterID].compactMap(\.self) : taught.map(\.chapterID))
        let weak = order
            .sorted(skills.filter { [.practising, .revisit].contains($0.state) && chapters.contains($0.chapterID) })
        if !weak.isEmpty {
            return weak.prefix(practiseLimit).map(\.name)
        }
        var names: [String] = []
        for check in wrong.sorted(by: { $0.at < $1.at }) {
            if let name = skills.first(where: { $0.id == check.skillID })?.name, !names.contains(name) {
                names.append(name)
            }
        }
        return Array(names.prefix(practiseLimit))
    }

    /// The next skill not started after the current one (a new chapter's name when it opens one), then the nearest exam
    /// reaching the student within its window from the note day.
    private static func coming(_ record: NoteRecord, order: Order, week: ClosedRange<Day>, calendar: Calendar)
        -> [String] {
        var coming: [String] = []
        let sorted = order.sorted(record.skills)
        let current = sorted.firstIndex { $0.state != .secure }
        if let current, let next = sorted[current...].first(where: { $0.state == .notStarted }) {
            let opensChapter = !sorted.contains { $0.chapterID == next.chapterID && $0.state != .notStarted }
            coming.append(opensChapter ? order.chapter(next)?.name ?? next.name : next.name)
        }
        if let exam = SchoolItemRules.nearestExam(
            for: record.student, items: record.items, students: [record.student], today: week.upperBound,
            calendar: calendar
        ) {
            coming.append("the \(lowered(exam.title)) on \(exam.date.shortWeekdayText)")
        }
        return coming
    }

    private static func attendanceWords(absences: Int, classes: Int) -> String? {
        guard absences > 0 else { return nil }
        if absences == classes {
            return "absent all week (\(classes) \(classes == 1 ? "class" : "classes"))"
        }
        return "absent \(absences) of \(classes) classes"
    }

    /// "Balancing equations" → "balancing equations"; a name that starts with an acronym stays.
    public static func lowered(_ text: String) -> String {
        let characters = Array(text)
        guard let first = characters.first, characters.count < 2 || !characters[1].isUppercase else { return text }
        return first.lowercased() + String(characters.dropFirst())
    }

    /// Skills in chapter order, then skill order.
    struct Order {
        let chapters: [UUID: Chapter]

        init(chapters: [Chapter]) {
            self.chapters = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
        }

        func chapter(_ skill: Skill) -> Chapter? {
            chapters[skill.chapterID]
        }

        func sorted(_ skills: [Skill]) -> [Skill] {
            skills.filter { chapters[$0.chapterID] != nil }.sorted { lhs, rhs in
                let (left, right) = (chapters[lhs.chapterID]?.position ?? 0, chapters[rhs.chapterID]?.position ?? 0)
                return left != right ? left < right : lhs.position < rhs.position
            }
        }
    }
}
