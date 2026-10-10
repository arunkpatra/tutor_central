import Foundation

/// What the plan's rules read for one batch on one day.
public struct PlanInput: Sendable {
    public let classroom: Classroom
    public let date: Day
    /// The batch's active members.
    public let students: [Student]
    /// By student.
    public let chapters: [UUID: [Chapter]]
    public let skills: [UUID: [Skill]]
    /// The batch's sessions, any month, for the catch-up line.
    public let sessions: [AttendanceSession]
    /// Phase 13 fills it; empty now.
    public let schoolItems: [SchoolItemHint]
    public let now: Date
    public let calendar: Calendar
    /// Today's choices from the Change sheet (nil: the batch's kept pattern, else the rules).
    public let groupCount: Int?
    /// By group number.
    public let subjects: [Int: String]

    public init(
        classroom: Classroom, date: Day, students: [Student], chapters: [UUID: [Chapter]], skills: [UUID: [Skill]],
        sessions: [AttendanceSession], schoolItems: [SchoolItemHint], now: Date, calendar: Calendar,
        groupCount: Int?, subjects: [Int: String]
    ) {
        self.classroom = classroom
        self.date = date
        self.students = students
        self.chapters = chapters
        self.skills = skills
        self.sessions = sessions
        self.schoolItems = schoolItems
        self.now = now
        self.calendar = calendar
        self.groupCount = groupCount
        self.subjects = subjects
    }

    /// The batch's kept pattern for the day's weekday.
    var pattern: PlanPattern? {
        classroom.planPattern[date.weekday(in: calendar)]
    }
}

/// A school item near enough to choose a student's subject (a test on Friday): Phase 13's.
public struct SchoolItemHint: Hashable, Sendable {
    public let studentID: UUID
    public let subject: String
    public let date: Day

    public init(studentID: UUID, subject: String, date: Day) {
        self.studentID = studentID
        self.subject = subject
        self.date = date
    }
}

/// The plan's rules (docs/spec-v2.md section 6; plan/phase-12-plan.md decisions 2 to 4): the level groups, each
/// student's subject and lines, made on the phone from the register and the record (D60). Pure.
public enum PlanRules {
    public static let maxGroups = 3
    public static let catchUpAfterAbsences = 2
    public static let schoolItemWindowDays = 14

    /// The draft: groups (largest first), one teach, practise, check and homework line per student (a catch-up line
    /// before the teach line when the student missed the last two), a brief line per group above class 7. A group whose
    /// members have no skill in its subject has `skill == ""` and `chapter == ""`: the maker asks /ai/plan for them.
    public static func plan(_ input: PlanInput) -> PlanDraft {
        let count = input.groupCount ?? input.pattern?.groups ?? input.classroom.planGroups
        let cut = groups(input.students, count: count)
        let ranked = cut.sorted { lhs, rhs in
            if lhs.count != rhs.count {
                return lhs.count > rhs.count
            }
            return (lhs.map(levelKey).max() ?? 0) > (rhs.map(levelKey).max() ?? 0)
        }
        var planned: [PlanGroup] = []
        var lines: [PlanLine] = []
        for (index, members) in ranked.enumerated() {
            let number = index + 1
            let override = input.subjects[number] ?? input.pattern?.subjects[safe: index]
            let subject = groupSubject(members, input: input, override: override)
            let group = group(number, members: members, subject: subject, input: input)
            planned.append(group)
            lines += members.flatMap { studentLines($0, group: group, input: input) }
            lines.append(PlanLine(
                studentID: nil, groupNo: number, kind: .workedExample, skillID: group.skillID,
                words: groupLineWords(.workedExample, group)
            ))
            if let figure = figureLine(group) {
                lines.append(figure)
            }
            if group.classLevels.contains(where: { $0 > .seven }) {
                lines.append(briefLine(group))
            }
        }
        return PlanDraft(classID: input.classroom.id, date: input.date, groups: planned, lines: lines, leftOut: [])
    }

    /// The brief's title and line before its chapter ("Your brief · Chemical reactions").
    public static let briefPrefix = "Your brief · "

    /// A teach line while /ai/plan has not named the group's skill.
    public static let withTheGroup = "Teach: with the group"

    /// The words of a group's worked example and figure lines ("Worked example · Balancing equations"): kept in the
    /// record, not shown as lines.
    static func groupLineWords(_ kind: PlanLineKind, _ group: PlanGroup) -> String {
        let name = kind == .figure ? "Figure" : "Worked example"
        return group.skill.isEmpty ? name : "\(name) · \(group.skill)"
    }

    /// The group's figure line when its skill names a template (plan decision 7).
    static func figureLine(_ group: PlanGroup) -> PlanLine? {
        guard !group.skill.isEmpty, FigureSpec.Kind.matching(skill: group.skill) != nil else { return nil }
        return PlanLine(
            studentID: nil, groupNo: group.number, kind: .figure, skillID: group.skillID,
            words: groupLineWords(.figure, group)
        )
    }

    /// The group's brief line ("Your brief · Chemical reactions"; "Your brief" until the chapter is named).
    public static func briefLine(_ group: PlanGroup) -> PlanLine {
        let words = group.chapter.isEmpty ? "Your brief" : briefPrefix + group.chapter
        return PlanLine(studentID: nil, groupNo: group.number, kind: .brief, skillID: nil, words: words)
    }

    // MARK: - Groups

    /// The class level's ordinal (LKG 0 to class 10 11), one less for a student not on track; -1 for no class (the
    /// grouping gives those the batch's most common level).
    static func levelKey(_ student: Student) -> Int {
        guard let level = student.classLevel, let ordinal = ClassLevel.allCases.firstIndex(of: level) else { return -1 }
        return student.trackStatus == .notOnTrack ? ordinal - 1 : ordinal
    }

    /// The students sorted by level key then name, cut at the largest gaps into `count` groups (ties: the later gap);
    /// without a count, the smaller of three and the number of distinct levels.
    static func groups(_ students: [Student], count: Int?) -> [[Student]] {
        guard !students.isEmpty else { return [] }
        let known = students.map(levelKey).filter { $0 >= 0 }
        let common = Dictionary(grouping: known, by: \.self)
            .max { lhs, rhs in
                lhs.value.count != rhs.value.count ? lhs.value.count < rhs.value.count : lhs.key < rhs.key
            }?
            .key ?? 0
        let keyed = students.map { (student: $0, key: levelKey($0) < 0 ? common : levelKey($0)) }
            .sorted { $0.key != $1.key ? $0.key < $1.key : $0.student.name < $1.student.name }
        let distinct = Set(keyed.map(\.key)).count
        let wanted = min(max(count ?? min(maxGroups, distinct), 1), maxGroups, distinct)
        let gaps = (0 ..< keyed.count - 1).map { (at: $0, size: keyed[$0 + 1].key - keyed[$0].key) }
        let cuts = gaps.sorted { $0.size != $1.size ? $0.size > $1.size : $0.at > $1.at }
            .prefix(wanted - 1).map(\.at).sorted()
        var result: [[Student]] = []
        var start = 0
        for cut in cuts + [keyed.count - 1] {
            result.append(keyed[start ... cut].map(\.student).sorted { $0.name < $1.name })
            start = cut + 1
        }
        return result
    }

    private static func group(_ number: Int, members: [Student], subject: String, input: PlanInput) -> PlanGroup {
        let taught = members.compactMap { student in
            teachSkill(for: student, subject: subject, input: input).map { (student, $0) }
        }
        let byName = Dictionary(grouping: taught, by: \.1.name)
        let chosen = taught.max { lhs, rhs in
            let (left, right) = (byName[lhs.1.name]?.count ?? 0, byName[rhs.1.name]?.count ?? 0)
            if left != right {
                return left < right
            }
            return (taught.firstIndex { $0.1.id == lhs.1.id } ?? 0) > (taught.firstIndex { $0.1.id == rhs.1.id } ?? 0)
        }
        let chapter = chosen.flatMap { student, skill in
            input.chapters[student.id]?.first { $0.id == skill.chapterID }?.name
        }
        return PlanGroup(
            number: number, subject: subject, chapter: chapter ?? "", skill: chosen?.1.name ?? "",
            classLevels: Array(Set(members.compactMap(\.classLevel))).sorted(), memberIDs: members.map(\.id),
            skillID: chosen?.1.id
        )
    }

    // MARK: - Subjects

    /// The student's subject: the nearest school item within 14 days, else the subject least recently taught (one never
    /// taught first), ties by the batch's subject then by name; nil when the student has no chapters.
    static func subject(for student: Student, input: PlanInput) -> String? {
        let soon = input.date.adding(days: schoolItemWindowDays, calendar: input.calendar)
        if let item = input.schoolItems
            .filter({ $0.studentID == student.id && $0.date >= input.date && $0.date <= soon })
            .min(by: { $0.date < $1.date }) {
            return item.subject
        }
        let chapters = input.chapters[student.id] ?? []
        let skills = input.skills[student.id] ?? []
        let subjects = Set(chapters.map(\.subject))
        guard !subjects.isEmpty else { return nil }
        let latest = { (subject: String) -> Date? in
            let ids = Set(chapters.filter { $0.subject == subject }.map(\.id))
            return skills.filter { ids.contains($0.chapterID) && $0.state != .notStarted }.map(\.stateAt).max()
        }
        return subjects.min { lhs, rhs in
            switch (latest(lhs), latest(rhs)) {
            case (nil, _?): true
            case (_?, nil): false
            case let (left?, right?) where left != right: left < right
            default: tieBreak(lhs, rhs, batch: input.classroom.subject)
            }
        }
    }

    /// The group's subject: today's choice or the kept pattern, else the most common among its members, ties by the
    /// batch's subject then by name; the batch's subject when no member has one.
    static func groupSubject(_ members: [Student], input: PlanInput, override: String?) -> String {
        if let override {
            return override
        }
        let counts = Dictionary(grouping: members.compactMap { subject(for: $0, input: input) }, by: \.self)
        let best = counts.max { lhs, rhs in
            lhs.value.count != rhs.value.count
                ? lhs.value.count < rhs.value.count : !tieBreak(lhs.key, rhs.key, batch: input.classroom.subject)
        }
        return best?.key ?? input.classroom.subject ?? "Mathematics"
    }

    /// True when `lhs` comes first: the batch's own subject, then by name.
    private static func tieBreak(_ lhs: String, _ rhs: String, batch: String?) -> Bool {
        if lhs == batch || rhs == batch {
            return lhs == batch && rhs != batch
        }
        return lhs < rhs
    }

    // MARK: - Lines

    /// The student's first skill not secure in the subject's chapters.
    static func teachSkill(for student: Student, subject: String, input: PlanInput) -> Skill? {
        let chapters = (input.chapters[student.id] ?? []).filter { $0.subject == subject }
        return TrackingRules.currentSkill(skills: input.skills[student.id] ?? [], chapters: chapters)
    }

    private static func studentLines(_ student: Student, group: PlanGroup, input: PlanInput) -> [PlanLine] {
        let chapters = (input.chapters[student.id] ?? []).filter { $0.subject == group.subject }
        let ids = Set(chapters.map(\.id))
        let skills = (input.skills[student.id] ?? []).filter { ids.contains($0.chapterID) }
        let own = chapters.isEmpty ? nil : teachSkill(for: student, subject: group.subject, input: input)
        let skillName = own?.name ?? group.skill
        let skillID = own?.id ?? group.skillID
        let placement = !chapters.isEmpty && skills.allSatisfy { $0.state == .notStarted }
        let again = !chapters.isEmpty && !placement && [.watch, .notOnTrack].contains(student.trackStatus)
        let missed = catchUp(for: student, input: input)
        let line = { (kind: PlanLineKind, words: String, personal: Bool) in
            PlanLine(
                studentID: student.id, groupNo: group.number, kind: kind, skillID: skillID, words: words,
                personalChecks: personal
            )
        }
        var lines: [PlanLine] = []
        if let missed {
            let then = skillName.isEmpty ? "" : " · then \(skillName)"
            lines.append(line(.catchUp, missed + then, false))
        }
        let teach = skillName.isEmpty
            ? withTheGroup
            : again ? "Teach again: \(skillName), with the worked example" : "Teach: \(skillName)"
        lines.append(line(.teach, teach, false))
        lines.append(line(.practise, "Practise set 1", false))
        let personal = !chapters.isEmpty && (placement || again || missed != nil)
        lines.append(line(.check, placement ? "Placement, \(pronoun(student)) first checks" : "Check 3", personal))
        lines.append(line(.homework, homeworkWords(student.classLevel), false))
        return lines
    }

    /// "Catch up: missed Mon and Fri" when the student was absent at the batch's last two sessions before the day.
    static func catchUp(for student: Student, input: PlanInput) -> String? {
        let last = input.sessions
            .filter { $0.classID == input.classroom.id && $0.date < input.date && $0.marks[student.id] != nil }
            .sorted { $0.date > $1.date }
            .prefix(catchUpAfterAbsences)
        guard last.count == catchUpAfterAbsences, last.allSatisfy({ $0.marks[student.id] == .absent }) else {
            return nil
        }
        let days = last.reversed().map { $0.date.weekday(in: input.calendar).short }
        return "Catch up: missed \(days.joined(separator: " and "))"
    }

    /// "Homework sheet 1", "Homework sheet 1, light" up to class 5.
    public static func homeworkWords(_ level: ClassLevel?) -> String {
        level?.homeworkIsLight == true ? "Homework sheet 1, light" : "Homework sheet 1"
    }

    /// "her", "his", "their" (the placement line).
    public static func pronoun(_ student: Student) -> String {
        switch student.gender {
        case .female: "her"
        case .male: "his"
        default: "their"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
