import Foundation

/// One day of an exam's preparation (P10-School-Item's Preparation): a revision day with its portion, the mock, a day
/// after the mock (the gap report's), or the test itself.
public struct PreparationDay: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable { case revise(index: Int), mock, afterMock, exam }

    public var id: Day {
        day
    }

    public let day: Day
    public let kind: Kind
    /// "Acids, bases and salts · first half", "The mock", "What the mock showed", "The test".
    public let title: String
    public let skills: [String]
    public let skillIDs: [UUID]

    public init(day: Day, kind: Kind, title: String, skills: [String] = [], skillIDs: [UUID] = []) {
        self.day = day
        self.kind = kind
        self.title = title
        self.skills = skills
        self.skillIDs = skillIDs
    }
}

/// What the split reads besides the student: their batch, the day, the holidays, the students, the centre's calendar.
public struct PreparationContext: Sendable {
    public let batch: Classroom
    public let today: Day
    public let holidays: [SchoolItem]
    public let students: [Student]
    public let calendar: Calendar

    public init(batch: Classroom, today: Day, holidays: [SchoolItem], students: [Student], calendar: Calendar) {
        self.batch = batch
        self.today = today
        self.holidays = holidays
        self.students = students
        self.calendar = calendar
    }
}

/// The exam window and the split of portions across the batch's days (docs/spec-v2.md section 6.6;
/// plan/phase-13-plan.md
/// decisions 8 and 9). Pure: the plan maker and the exam's page both read it.
public enum ExamPreparation {
    public static let windowDays = SchoolItemRules.windowDays
    public static let mockDaysBefore = 2

    /// The portions cut into parts at "·", ";", new lines and "Ch n" markers, each without its "Ch n" prefix when words
    /// follow it.
    public static func portions(_ text: String) -> [String] {
        text.split(whereSeparator: { "·;\n".contains($0) })
            .flatMap { splitAtMarkers(String($0)) }
            .map { dropMarker($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
    }

    /// The student's chapters a part names: either name contains the other, ignoring case and a "Ch n" prefix; else the
    /// chapters whose numbers it gives ("Ch 2", "chapters 1 and 2", "chapters 1 to 3").
    public static func matching(_ portion: String, in chapters: [Chapter]) -> [Chapter] {
        let words = dropMarker(portion.trimmingCharacters(in: .whitespaces)).lowercased()
        guard !words.isEmpty else { return [] }
        let named = chapters.filter {
            let name = $0.name.lowercased()
            return words.contains(name) || name.contains(words)
        }
        guard named.isEmpty else { return named.sorted { $0.position < $1.position } }
        let positions = chapterNumbers(portion)
        return chapters.filter { positions.contains($0.position) }.sorted { $0.position < $1.position }
    }

    /// The chapter numbers a part gives after "Ch", "Chapter" or "Chapters": a list, or a range with "to" or "-".
    static func chapterNumbers(_ text: String) -> Set<Int> {
        var numbers: Set<Int> = []
        for match in text.matches(of: /(?i:\bch(?:apters?)?\.?\s*(\d+(?:\s*(?:,|and|&|to|-)\s*\d+)*))/) {
            let run = String(match.1)
            let values = run.matches(of: /\d+/).compactMap { Int($0.output) }
            if run.contains("to") || run.contains("-"), values.count == 2, let low = values.first,
               let high = values.last,
               low <= high {
                numbers.formUnion(low ... high)
            } else {
                numbers.formUnion(values)
            }
        }
        return numbers
    }

    public static func isWithinWindow(_ exam: SchoolItem, today: Day, calendar _: Calendar) -> Bool {
        let days = today.days(to: exam.date)
        return exam.kind == .exam && days >= 0 && days <= windowDays
    }

    /// The student's weakest skill among the names: one to revisit, then practising, then taught; none when every
    /// skill named is secure or not started.
    public static func weakest(_ skills: [Skill], among names: [String]) -> Skill? {
        let named = skills.filter { names.contains($0.name) }
        for state in [SkillState.revisit, .practising, .taught] {
            if let skill = named.first(where: { $0.state == state }) {
                return skill
            }
        }
        return nil
    }

    /// The days from today to the exam for one student of the batch: the batch's meeting days before the exam, less the
    /// student's holidays, then the exam day. With three days or more the mock takes the last meeting day at least two
    /// days before the exam (one revision day before it at least) and the days after it are the gap report's; with
    /// fewer, every day is revision.
    public static func days(
        exam: SchoolItem, student: Student, chapters: [Chapter], skills: [Skill], context: PreparationContext
    ) -> [PreparationDay] {
        let (batch, today, calendar) = (context.batch, context.today, context.calendar)
        let count = max(0, today.days(to: exam.date))
        let meeting = (0 ..< count).map { today.adding(days: $0, calendar: calendar) }
            .filter { batch.meetingDays.contains($0.weekday(in: calendar)) }
            .filter { !HolidayRules.onHoliday(student, on: $0, items: context.holidays, students: context.students) }
        var revision = meeting
        var after: [Day] = []
        var mockDay: Day?
        if meeting.count >= 3 {
            let latest = exam.date.adding(days: -mockDaysBefore, calendar: calendar)
            let index = meeting.lastIndex(where: { $0 <= latest }).map { max($0, 1) } ?? meeting.count - 1
            mockDay = meeting[index]
            revision = Array(meeting[..<index])
            after = Array(meeting[(index + 1)...])
        }
        let parts = portions(exam.portions ?? exam.title)
        var result = spread(parts.isEmpty ? [exam.title] : parts, over: revision, chapters: chapters, skills: skills)
        if let mockDay {
            result.append(PreparationDay(day: mockDay, kind: .mock, title: "The mock"))
        }
        result += after.map { PreparationDay(day: $0, kind: .afterMock, title: "What the mock showed") }
        result.append(PreparationDay(day: exam.date, kind: .exam, title: "The test"))
        return result
    }

    /// The parts over the revision days in order: a part over k days in k runs of its skills, or several parts on one
    /// day when the days are fewer.
    static func spread(_ parts: [String], over days: [Day], chapters: [Chapter], skills: [Skill]) -> [PreparationDay] {
        guard !days.isEmpty else { return [] }
        let named = parts.map { part -> (title: String, skills: [Skill]) in
            let matched = matching(part, in: chapters)
            let own = matched
                .flatMap { chapter in
                    skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
                }
            return (part, own)
        }
        var result: [PreparationDay] = []
        if days.count >= parts.count {
            let shares = sizes(days.count, into: parts.count)
            var next = 0
            for (part, share) in zip(named, shares) {
                let runs = sizes(part.skills.count, into: share)
                var start = 0
                for run in 0 ..< share {
                    let size = runs[run]
                    let slice = size > 0 ? Array(part.skills[start ..< start + size]) : part.skills
                    start += size
                    let title = share == 1 ? part.title : "\(part.title) · \(runWords(run, of: share))"
                    result.append(day(days[next], index: next + 1, title: title, part: part.title, skills: slice))
                    next += 1
                }
            }
        } else {
            let groups = sizes(parts.count, into: days.count)
            var start = 0
            for (index, size) in groups.enumerated() {
                let group = named[start ..< start + size]
                start += size
                let skillsOfDay = group.flatMap(\.skills)
                let words = group.flatMap { $0.skills.isEmpty ? [$0.title] : $0.skills.map(\.name) }
                result.append(PreparationDay(
                    day: days[index], kind: .revise(index: index + 1),
                    title: group.map(\.title).joined(separator: " · "),
                    skills: words, skillIDs: skillsOfDay.map(\.id)
                ))
            }
        }
        return result
    }

    private static func day(_ day: Day, index: Int, title: String, part: String, skills: [Skill]) -> PreparationDay {
        PreparationDay(
            day: day, kind: .revise(index: index), title: title,
            skills: skills.isEmpty ? [part] : skills.map(\.name), skillIDs: skills.map(\.id)
        )
    }

    /// n split into k sizes as even as possible, the larger first: 4 into 3 is 2, 1, 1.
    static func sizes(_ total: Int, into parts: Int) -> [Int] {
        guard parts > 0 else { return [] }
        return (0 ..< parts).map { total / parts + ($0 < total % parts ? 1 : 0) }
    }

    private static func runWords(_ run: Int, of count: Int) -> String {
        if count == 2 {
            return run == 0 ? "first half" : "second half"
        }
        return "part \(run + 1) of \(count)"
    }

    private static var marker: Regex<Substring> {
        /(?i:\bch(?:apter)?\.?\s*\d+\b)/
    }

    /// "Ch 1 Chemical reactions Ch 2 Acids" in two parts, each starting at its marker.
    private static func splitAtMarkers(_ text: String) -> [String] {
        let starts = text.matches(of: marker).map(\.range.lowerBound).filter { $0 != text.startIndex }
        guard !starts.isEmpty else { return [text] }
        var parts: [String] = []
        var from = text.startIndex
        for start in starts {
            parts.append(String(text[from ..< start]))
            from = start
        }
        parts.append(String(text[from...]))
        return parts
    }

    /// "Ch 1 Chemical reactions" → "Chemical reactions"; "Ch 1" alone stays.
    private static func dropMarker(_ text: String) -> String {
        guard let match = text.prefixMatch(of: marker) else { return text }
        let rest = text[match.range.upperBound...].trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? text : rest
    }
}
