import Foundation

/// Who an item reaches, how it reads in a list, and the exam that drives a student's revision (docs/spec-v2.md
/// sections 4 and 6.6; plan/phase-13-plan.md decisions 2, 4 and 8).
public enum SchoolItemRules {
    public static let portionsLimit = 500
    public static let titleLimit = 120
    /// An exam this close turns its students' lines to revision (spec 6.6); a per-exam window waits for a board.
    public static let windowDays = 14

    /// Whether the item is for the student: their own, their school's class, or their whole school. A student added to
    /// the class later is reached too; an archived one is not.
    public static func reaches(_ item: SchoolItem, _ student: Student) -> Bool {
        guard student.archivedAt == nil else { return false }
        switch item.audience {
        case let .student(id): return student.id == id
        case let .schoolClass(school, level): return student.schoolID == school && student.classLevel == level
        case let .school(school): return student.schoolID == school
        }
    }

    /// The active students the item reaches, by name.
    public static func students(for item: SchoolItem, in students: [Student]) -> [Student] {
        students.filter { reaches(item, $0) }.sorted { $0.name < $1.name }
    }

    /// "Class 8 at Vidya Niketan · Dev, Meher, Nikhil"; "Vidya Niketan, every class"; "Riya Sharma · St Mary's School".
    public static func audienceLine(_ item: SchoolItem, students: [Student], schools: [School]) -> String {
        switch item.audience {
        case let .student(id):
            guard let student = students.first(where: { $0.id == id }) else { return "A student no longer here" }
            let school = schools.first { $0.id == student.schoolID }?.name
            return [student.name, school].compactMap(\.self).joined(separator: " · ")
        case let .schoolClass(school, level):
            let place = "\(level.title) at \(schoolName(school, schools))"
            let names = Self.students(for: item, in: students).map(\.firstName).sorted()
            let noOne = "no one in \(level.hasChapters ? level.title.lowercased() : level.title) there yet"
            return "\(place) · \(names.isEmpty ? noOne : names.joined(separator: ", "))"
        case let .school(school):
            return "\(schoolName(school, schools)), every class"
        }
    }

    /// "today", "tomorrow", "in 9 days"; nothing once the day has passed.
    public static func countdown(from today: Day, to date: Day) -> String? {
        switch today.days(to: date) {
        case ..<0: nil
        case 0: "today"
        case 1: "tomorrow"
        case let days: "in \(days) days"
        }
    }

    /// The list from today on (an item whose last day has not passed): This week (to Sunday), Next week, Later, each by
    /// date then title; empty groups left out.
    public static func buckets(
        _ items: [SchoolItem],
        today: Day,
        calendar: Calendar
    ) -> [(title: String, items: [SchoolItem])] {
        let thisSunday = today.adding(days: 7 - today.weekday(in: calendar).rawValue, calendar: calendar)
        let nextSunday = thisSunday.adding(days: 7, calendar: calendar)
        let current = sorted(items.filter { $0.lastDay >= today })
        let groups: [(String, [SchoolItem])] = [
            ("This week", current.filter { $0.date <= thisSunday }),
            ("Next week", current.filter { $0.date > thisSunday && $0.date <= nextSunday }),
            ("Later", current.filter { $0.date > nextSunday }),
        ]
        return groups.filter { !$0.1.isEmpty }.map { (title: $0.0, items: $0.1) }
    }

    /// A list row's second line: who, the subject (an exam's, when the title does not name it), and the countdown (an
    /// exam) or a holiday's last day.
    public static func line(_ item: SchoolItem, today: Day, students: [Student], schools: [School]) -> String {
        var parts: [String] = []
        if case let .school(school) = item.audience {
            parts.append(schoolName(school, schools))
        } else {
            parts.append(audienceLine(item, students: students, schools: schools))
        }
        if item.kind == .exam, let subject = item.subject, !subject.isEmpty,
           !item.title.localizedCaseInsensitiveContains(subject) {
            parts.append(subject)
        }
        switch item.kind {
        case .exam:
            if let countdown = countdown(from: today, to: item.date) {
                parts.append(countdown)
            }
        case .holiday:
            if let end = item.endDate, end > item.date {
                parts.append("to \(end.shortWeekdayText)")
            }
        case .homework, .notice:
            break
        }
        return parts.joined(separator: " · ")
    }

    /// The exam that drives the student's revision: the earliest exam reaching them within the window from today (ties
    /// by title); once it passes, the next one does.
    public static func nearestExam(
        for student: Student,
        items: [SchoolItem],
        students _: [Student],
        today: Day,
        calendar: Calendar
    ) -> SchoolItem? {
        let last = today.adding(days: windowDays, calendar: calendar)
        return sorted(items.filter { $0.kind == .exam && $0.date >= today && $0.date <= last && reaches($0, student) })
            .first
    }

    /// Each active student's nearest exam with a subject, for the plan's subject rule (Phase 12's hint).
    public static func hints(
        _ items: [SchoolItem],
        students: [Student],
        today: Day,
        calendar: Calendar
    ) -> [SchoolItemHint] {
        students.filter { $0.archivedAt == nil }.compactMap { student in
            guard let exam = nearestExam(
                for: student,
                items: items,
                students: students,
                today: today,
                calendar: calendar
            ),
                let subject = exam.subject, !subject.isEmpty else { return nil }
            return SchoolItemHint(studentID: student.id, subject: subject, date: exam.date)
        }
    }

    /// The items reaching the student whose last day has not passed, by date then title (the student page's School).
    public static func upcoming(
        for student: Student,
        items: [SchoolItem],
        students _: [Student],
        today: Day
    ) -> [SchoolItem] {
        sorted(items.filter { $0.lastDay >= today && reaches($0, student) })
    }

    static func sorted(_ items: [SchoolItem]) -> [SchoolItem] {
        items.sorted { ($0.date, $0.title) < ($1.date, $1.title) }
    }

    static func schoolName(_ id: UUID, _ schools: [School]) -> String {
        schools.first { $0.id == id }?.name ?? "A school"
    }
}
