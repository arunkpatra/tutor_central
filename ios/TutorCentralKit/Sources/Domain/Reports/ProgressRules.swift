import Foundation

/// The span a progress report covers: a month, or a school term.
public enum ProgressSpan: Hashable, Sendable {
    case month(Period), term(Term)

    public var months: [Period] {
        switch self {
        case let .month(period): [period]
        case let .term(term): term.months
        }
    }

    /// "October 2026", "Term 1 · June to September".
    public var title: String {
        switch self {
        case let .month(period): "\(Self.monthNames[period.month - 1]) \(period.year)"
        case let .term(term): term.title
        }
    }

    /// "2026-10", "term-1-2026".
    public var fileStem: String {
        switch self {
        case let .month(period): period.isoMonth
        case let .term(term): term.fileStem
        }
    }

    public func hasEnded(_ now: Day) -> Bool {
        months.last.map { now.period > $0 } ?? false
    }

    func contains(_ day: Day) -> Bool {
        months.contains(day.period)
    }

    private static let monthNames = [
        "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November",
        "December",
    ]
}

/// One student's record for the span, as `ProgressReader` reads it.
public struct ProgressInput: Hashable, Sendable {
    public let student: Student
    public let chapters: [Chapter]
    public let skills: [Skill]
    public let checks: [CheckRecord]
    public let sessions: [AttendanceSession]
    public let span: ProgressSpan
    public let calendar: Calendar

    public init(
        student: Student, chapters: [Chapter], skills: [Skill], checks: [CheckRecord], sessions: [AttendanceSession],
        span: ProgressSpan, calendar: Calendar
    ) {
        self.student = student
        self.chapters = chapters
        self.skills = skills
        self.checks = checks
        self.sessions = sessions
        self.span = span
        self.calendar = calendar
    }
}

/// A row of Progress (P10-Reports-Progress) and of its CSV.
public struct ProgressRow: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let initials: String
    public let className: String
    public let status: TrackStatus
    /// "3 skills secure · 41% right · 2 absences", "Reading: Sentences · Numbers: To 99", "No checks yet".
    public let line: String
    public let skillsSecure: Int
    public let checks: Int
    public let right: Int
    public let absences: Int
    public let percent: Int?

    public init(
        id: UUID, name: String, initials: String, className: String, status: TrackStatus, line: String,
        skillsSecure: Int, checks: Int, right: Int, absences: Int, percent: Int?
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.className = className
        self.status = status
        self.line = line
        self.skillsSecure = skillsSecure
        self.checks = checks
        self.right = right
        self.absences = absences
        self.percent = percent
    }

    /// "41%", or "–" with no checks.
    public var percentText: String {
        percent.map { "\($0)%" } ?? "–"
    }
}

/// The hero over the rows: skills made secure, checks right, not on track.
public struct ProgressHero: Hashable, Sendable {
    public let skillsSecure: Int
    public let rightText: String
    public let notOnTrack: Int
    public let notOnTrackLabel: String
}

public enum ProgressSort: CaseIterable, Hashable, Sendable {
    case lowestFirst, highestFirst, byName

    public var title: String {
        switch self {
        case .lowestFirst: "Lowest first"
        case .highestFirst: "Highest first"
        case .byName: "By name"
        }
    }
}

/// Each student's progress over a month or a term (plan/phase-15-plan.md decision 16): skills made secure in the span,
/// the span's checks without placements and how many were right, the span's absences, the status now.
public enum ProgressRules {
    public static func row(_ input: ProgressInput, className: String) -> ProgressRow {
        let student = input.student
        let inSpan = { (date: Date) in input.span.contains(Day(date, calendar: input.calendar)) }
        let secure = input.skills.count { $0.state == .secure && inSpan($0.stateAt) }
        let checks = input.checks.filter { !$0.isPlacement && inSpan($0.at) }
        let right = checks.count(where: \.correct)
        let absences = input.sessions.count { input.span.contains($0.date) && $0.marks[student.id] == .absent }
        let percent = checks.isEmpty ? nil : Int((Double(right) * 100 / Double(checks.count)).rounded())
        let lead = lead(input, secure: secure, checks: checks.count, percent: percent)
        let line = ([lead] + (absences > 0 ? [counted(absences, "absence")] : [])).joined(separator: " · ")
        return ProgressRow(
            id: student.id, name: student.name, initials: student.initials, className: className,
            status: student.trackStatus, line: line, skillsSecure: secure, checks: checks.count, right: right,
            absences: absences, percent: percent
        )
    }

    public static func hero(_ rows: [ProgressRow], span: ProgressSpan, now: Day) -> ProgressHero {
        let checks = rows.reduce(0) { $0 + $1.checks }
        let right = rows.reduce(0) { $0 + $1.right }
        let rightText = checks == 0 ? "–" : "\(Int((Double(right) * 100 / Double(checks)).rounded()))%"
        return ProgressHero(
            skillsSecure: rows.reduce(0) { $0 + $1.skillsSecure }, rightText: rightText,
            notOnTrack: rows.count { $0.status == .notOnTrack },
            notOnTrackLabel: span.hasEnded(now) ? "not on track at the end" : "not on track"
        )
    }

    public static func sorted(_ rows: [ProgressRow], by sort: ProgressSort) -> [ProgressRow] {
        let byName = { (lhs: ProgressRow, rhs: ProgressRow) in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        return rows.sorted { lhs, rhs in
            switch (sort, lhs.percent, rhs.percent) {
            case (.byName, _, _): byName(lhs, rhs)
            case let (_, left?, right?) where left != right: sort == .lowestFirst ? left < right : left > right
            case (_, .some, nil): true
            case (_, nil, .some): false
            default: byName(lhs, rhs)
            }
        }
    }

    /// What leads the line: the ladder's steps for a young student, "Placed …" or the count of checks while the
    /// status is not known, else skills secure and the percent right.
    private static func lead(_ input: ProgressInput, secure: Int, checks: Int, percent: Int?) -> String {
        if let steps = ladderSteps(input) {
            return steps
        }
        if input.student.trackStatus == .notKnown {
            let given = input.checks.count { input.span.contains(Day($0.at, calendar: input.calendar)) }
            let placed = input.checks.filter(\.isPlacement).map(\.at).min()
            let count = given == 0 ? "No checks yet" : "\(counted(given, "check")) so far"
            return placed.map { "Placed \(Day($0, calendar: input.calendar).shortWeekdayText) · \(count)" } ?? count
        }
        guard let percent, checks > 0 else {
            return secure > 0 ? "\(counted(secure, "skill")) secure · No checks yet" : "No checks yet"
        }
        return "\(counted(secure, "skill")) secure · \(percent)% right"
    }

    /// "Reading: Sentences · Numbers: To 99": each ladder area whose current step is beyond the first; nil for a
    /// student without the ladder or on the first step everywhere.
    private static func ladderSteps(_ input: ProgressInput) -> String? {
        let parts: [String] = input.chapters.sorted { $0.position < $1.position }.compactMap { chapter in
            guard let area = chapter.ladder else { return nil }
            let states = input.skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
                .map(\.state)
            let step = Ladder.currentStep(states) ?? (area.steps.count - 1)
            guard step > 0, area.steps.indices.contains(step) else { return nil }
            return "\(area.title): \(area.steps[step])"
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func counted(_ count: Int, _ noun: String) -> String {
        "\(count) \(noun)\(count == 1 ? "" : "s")"
    }
}

/// The Progress file: student, class, status, skills secure, checks, right, absences (P5-Reports-Export's third
/// choice).
public enum ProgressCSV {
    public static func fileName(_ span: ProgressSpan) -> String {
        "progress-\(span.fileStem).csv"
    }

    public static func make(_ rows: [ProgressRow]) -> String {
        CSV.make(
            header: ["Student", "Class", "Status", "Skills secure", "Checks", "Right", "Absences"],
            rows: rows.map { row in
                [
                    row.name,
                    row.className,
                    row.status.title,
                    "\(row.skillsSecure)",
                    "\(row.checks)",
                    "\(row.right)",
                    "\(row.absences)",
                ]
            }
        )
    }
}
