import Foundation

/// What the tracking status is worked out from (one student).
public struct TrackingInput: Hashable, Sendable {
    /// The student's checks, any order and age; placement checks included.
    public var checks: [CheckRecord]
    /// Absences in the last 28 days.
    public var absences: Int
    /// The student's homework, any order.
    public var homework: [HomeworkRecord]
    public var skills: [Skill]
    public var chapters: [Chapter]
    public var classLevel: ClassLevel?
    public var now: Date
    public var calendar: Calendar

    public init(
        checks: [CheckRecord], absences: Int, homework: [HomeworkRecord], skills: [Skill], chapters: [Chapter],
        classLevel: ClassLevel?, now: Date, calendar: Calendar
    ) {
        self.checks = checks
        self.absences = absences
        self.homework = homework
        self.skills = skills
        self.chapters = chapters
        self.classLevel = classLevel
        self.now = now
        self.calendar = calendar
    }
}

/// A student's tracking status with its reasons and the "Next" line of the tracking card.
public struct Tracking: Hashable, Sendable {
    public let status: TrackStatus
    /// The fired rules' sentences; [] for on track and not known yet.
    public let reasons: [String]
    public let nextStep: String

    public init(status: TrackStatus, reasons: [String], nextStep: String) {
        self.status = status
        self.reasons = reasons
        self.nextStep = nextStep
    }
}

/// The tracking status rules (plan decision 8; Phase 12 refines them with the plan). Not known yet without a check;
/// otherwise the worst of four rules, each firing watch or not on track: check accuracy over three weeks (at least six
/// checks, the placement's left out), absences over four weeks, homework not done running, chapters behind the term.
public enum TrackingRules {
    public static let checkWindowDays = 21, absenceWindowDays = 28, minimumChecks = 6

    public static func evaluate(_ input: TrackingInput) -> Tracking {
        guard !input.checks.isEmpty else {
            return Tracking(
                status: .notKnown,
                reasons: [],
                nextStep: "Start with the class's first chapter until the checks say otherwise."
            )
        }
        var fired: [(TrackStatus, String)] = []
        if let absences = absenceRule(input.absences) {
            fired.append(absences)
        }
        if let homework = homeworkRule(input.homework) {
            fired.append(homework)
        }
        if let behind = chaptersBehind(
            skills: input.skills,
            chapters: input.chapters,
            now: input.now,
            calendar: input.calendar
        ) {
            fired.append((
                behind.behind >= 3 ? .notOnTrack : .watch,
                "\(behind.behind) chapters behind in \(behind.subject)"
            ))
        }
        if let accuracy = accuracyRule(input.checks, now: input.now, calendar: input.calendar) {
            fired.append(accuracy)
        }
        let status = fired.map(\.0).min() ?? .onTrack
        let current = currentSkill(skills: input.skills, chapters: input.chapters)
        return Tracking(status: status, reasons: fired.map(\.1), nextStep: nextStep(status, current: current))
    }

    /// The first skill not yet secure, by chapter then skill position; nil when there is none.
    public static func currentSkill(skills: [Skill], chapters: [Chapter]) -> Skill? {
        let positions = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0.position) })
        return skills
            .filter { $0.state != .secure && positions[$0.chapterID] != nil }
            .min { lhs, rhs in
                let (left, right) = (positions[lhs.chapterID] ?? 0, positions[rhs.chapterID] ?? 0)
                return left != right ? left < right : lhs.position < rhs.position
            }
    }

    /// Chapters started (a skill beyond not started) against the term calendar (June to March, ten months), per
    /// subject; the subject furthest behind when it is two or more chapters behind. The ladder is left out.
    public static func chaptersBehind(skills: [Skill], chapters: [Chapter], now: Date, calendar: Calendar)
        -> (subject: String, behind: Int)? {
        let month = calendar.component(.month, from: now)
        let monthsElapsed = min(max(((month - 6 + 12) % 12) + 1, 1), 10)
        let started = Set(skills.filter { $0.state != .notStarted }.map(\.chapterID))
        let bySubject = Dictionary(grouping: chapters.filter { $0.ladder == nil }, by: \.subject)
        let behind = bySubject.map { subject, list -> (subject: String, behind: Int) in
            let expected = Int((Double(list.count) * Double(monthsElapsed) / 10).rounded(.up))
            return (subject, expected - list.count { started.contains($0.id) })
        }
        guard let worst = behind.max(by: { lhs, rhs in
            lhs.behind != rhs.behind ? lhs.behind < rhs.behind : lhs.subject > rhs.subject
        }), worst.behind >= 2 else { return nil }
        return worst
    }

    private static func absenceRule(_ absences: Int) -> (TrackStatus, String)? {
        guard absences >= 2 else { return nil }
        return (absences >= 4 ? .notOnTrack : .watch, "Absent \(absences) times in four weeks")
    }

    private static func homeworkRule(_ homework: [HomeworkRecord]) -> (TrackStatus, String)? {
        let run = homework.sorted { $0.givenAt > $1.givenAt }.prefix { $0.status == .notDone }.count
        guard run >= 2 else { return nil }
        return (run >= 3 ? .notOnTrack : .watch, "Homework not done \(timesWord(run)) running")
    }

    private static func accuracyRule(_ checks: [CheckRecord], now: Date, calendar: Calendar) -> (TrackStatus, String)? {
        let from = calendar.date(byAdding: .day, value: -checkWindowDays, to: now) ?? now
        let window = checks.filter { !$0.isPlacement && $0.at >= from && $0.at <= now }
        guard window.count >= minimumChecks else { return nil }
        let right = window.count(where: \.correct)
        let share = Double(right) / Double(window.count)
        guard share < 0.7 else { return nil }
        return (share < 0.5 ? .notOnTrack : .watch, "\(right) of \(window.count) checks right over three weeks")
    }

    private static func nextStep(_ status: TrackStatus, current: Skill?) -> String {
        switch (status, current) {
        case let (.onTrack, skill?): "Continue with \(skill.name)."
        case let (.watch, skill?): "Teach \(skill.name) again with a worked example."
        case let (.notOnTrack, skill?): "Step back to the skill before \(skill.name)."
        case (.watch, nil): "Teach the last chapter again with a worked example."
        case (.notOnTrack, nil): "Tell the parent, then teach again with the worked example."
        case (.onTrack, nil): "Carry on with the next chapter."
        case (.notKnown, _): "Start with the class's first chapter until the checks say otherwise."
        }
    }

    private static func timesWord(_ count: Int) -> String {
        switch count {
        case 2: "twice"
        case 3: "three times"
        case 4: "four times"
        case 5: "five times"
        default: "\(count) times"
        }
    }
}
