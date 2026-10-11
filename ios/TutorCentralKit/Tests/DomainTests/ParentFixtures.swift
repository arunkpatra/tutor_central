import Foundation
@testable import Domain

/// The parents' tests' people and days (plan/phase-14-plan.md decision 28), on top of Phase 13's school samples: Dev's
/// parent Ramesh writes in Hindi and agreed; Sahil's parent Deepak in Kannada and agreed; Riya's parent Neha has not.
protocol ParentFixtures: SchoolSamples {}

extension ParentFixtures {
    var calendar: Calendar {
        DayHeading.india
    }

    /// A moment in India's calendar.
    func india(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func day(_ month: Int, _ day: Int) -> Day {
        Day(year: 2026, month: month, day: day)!
    }

    var devWithParent: Student {
        var student = dev
        student.parentName = "Ramesh Kumar"
        student.parentPhone = PhoneNumber(e164: "+919884843831")
        student.messageLanguage = .hindi
        student.consent = ConsentRecord(
            at: india(2026, 9, 20),
            phone: PhoneNumber(e164: "+919884843831")!,
            how: .whatsapp
        )
        return student
    }

    var feeMessage: FeeMessage {
        FeeMessage(
            kind: .reminder, parentName: "Ramesh Kumar", studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
            amount: Money(rupees: 1000), upiID: "meera@okhdfcbank", paymentLink: nil, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
    }

    var testTomorrow: TestTomorrowMessage {
        TestTomorrowMessage(
            parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test 3",
            date: day(10, 16), portions: "Chemical reactions", revise: nil, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
    }

    // MARK: Dev's week (5 to 11 October): three classes, two absences, 12 checks with 8 right, two skills taught.

    var week: ClosedRange<Day> {
        day(10, 5) ... day(10, 11)
    }

    var reactions: Chapter {
        Chapter(id: fixed("71"), subject: "Science", position: 1, name: "Chemical reactions")
    }

    var acids: Chapter {
        Chapter(id: fixed("72"), subject: "Science", position: 2, name: "Acids, bases and salts")
    }

    var parentChapters: [Chapter] {
        [reactions, acids]
    }

    /// Chapter 1: a word equation secure in September, balancing and types taught this week, the numbers in front
    /// practising since September; chapter 2 not started.
    func parentSkills(taughtThisWeek: Bool = true) -> [Skill] {
        let taughtAt = taughtThisWeek ? india(2026, 10, 6, 18, 30) : india(2026, 9, 29, 18, 30)
        return [
            parentSkill("11", "Writing a word equation", .secure, india(2026, 9, 20)),
            parentSkill("12", "Balancing equations", .taught, taughtAt),
            parentSkill("13", "Types of reactions", .taught, taughtAt.addingTimeInterval(86400 * 2)),
            parentSkill("14", "The numbers in front of a formula", .practising, india(2026, 9, 28)),
            parentSkill("21", "Naming acids", .notStarted, india(2026, 9, 1)),
            parentSkill("22", "Indicators", .notStarted, india(2026, 9, 1)),
        ]
    }

    /// A skill by its code: the chapter's digit, then the skill's position ("12": chapter 1, the second skill).
    func parentSkill(_ code: String, _ name: String, _ state: SkillState, _ at: Date) -> Skill {
        Skill(
            id: fixed(code), chapterID: code.hasPrefix("1") ? reactions.id : acids.id,
            position: Int(String(code.suffix(1)))!, name: name, state: state, stateAt: at, lastCheckedAt: nil
        )
    }

    /// Twelve checks over the week, eight right; the wrong ones on the numbers in front.
    var devChecks: [CheckRecord] {
        (0 ..< 12).map { index in
            CheckRecord(
                id: UUID(), studentID: dev.id, skillID: index < 8 ? fixed("12") : fixed("14"), sessionID: nil,
                question: "Q\(index)", correct: index < 8, at: india(2026, 10, 5 + index % 3 * 2, 18, 0),
                isPlacement: false
            )
        }
    }

    func moved(_ check: CheckRecord, to day: Day) -> CheckRecord {
        CheckRecord(
            id: check.id, studentID: check.studentID, skillID: check.skillID, sessionID: check.sessionID,
            question: check.question, correct: check.correct, at: day.date(in: calendar), isPlacement: false
        )
    }

    func asPlacement(_ check: CheckRecord) -> CheckRecord {
        CheckRecord(
            id: check.id, studentID: check.studentID, skillID: check.skillID, sessionID: nil,
            question: check.question, correct: check.correct, at: check.at, isPlacement: true
        )
    }

    func mark(subject: String, test: String, on date: Day, score: Int, max: Int) -> MarkRecord {
        MarkRecord(
            id: UUID(), studentID: dev.id, subject: subject, test: test, date: date, score: score, max: max,
            photoPath: nil, schoolItemID: nil, artefactID: nil, questions: nil
        )
    }

    var devMarks: [MarkRecord] {
        [
            mark(subject: "Science", test: "Unit test 1", on: day(9, 18), score: 20, max: 25),
            mark(subject: "Science", test: "Unit test 2", on: day(10, 9), score: 14, max: 25),
        ]
    }

    /// The unit test on Friday 16 October for class 8 at Vidya Niketan.
    var unitTest: SchoolItem {
        var item = exam16
        item.title = "Unit test"
        return item
    }

    /// The Evening batch's three classes this week (Mon, Wed, Fri); Dev absent Monday and Wednesday, or all three.
    func weekSessions(devAbsent all: Bool = false, others: [Student] = []) -> [AttendanceSession] {
        [day(10, 5), day(10, 7), day(10, 9)].enumerated().map { index, date in
            var marks: [UUID: AttendanceStatus] = [dev.id: all || index < 2 ? .absent : .present]
            for other in others {
                marks[other.id] = .present
            }
            return AttendanceSession(
                id: UUID(), classID: evening.id, date: date, savedAt: date.date(in: calendar), marks: marks
            )
        }
    }

    var newStudent: Student {
        student("Tara Menon", level: .eight, school: vidya.id)
    }

    // MARK: Sahil's ladder: reading to Sentences this week, writing to Letters, numbers to 99.

    func ladderChapter(_ area: Ladder.Area, position: Int) -> Chapter {
        Chapter(id: fixed("9\(position)"), subject: "Ladder", position: position, name: area.title, ladder: area)
    }

    var sahilLadder: [Chapter] {
        [
            ladderChapter(.reading, position: 1),
            ladderChapter(.writing, position: 2),
            ladderChapter(.numbers, position: 3),
        ]
    }

    /// Secure steps per area; the last secure reading step made secure this week unless `movedThisWeek` is false.
    func sahilSkills(movedThisWeek: Bool = true) -> [Skill] {
        let secure: [Ladder.Area: Int] = [.reading: 3, .writing: 2, .numbers: 2]
        return sahilLadder.flatMap { chapter -> [Skill] in
            let area = chapter.ladder!
            return area.steps.enumerated().map { index, step in
                let isSecure = index < secure[area]!
                let thisWeek = movedThisWeek && area == .reading && index == 2
                return Skill(
                    id: UUID(), chapterID: chapter.id, position: index + 1, name: step,
                    state: isSecure ? .secure : .notStarted,
                    stateAt: thisWeek ? india(2026, 10, 8, 17, 30) : india(2026, 9, 15), lastCheckedAt: nil
                )
            }
        }
    }

    // MARK: The cadence and the next step.

    var riyaWithParent: Student {
        var student = riya
        student.parentName = "Neha Sharma"
        student.parentPhone = PhoneNumber(e164: "+919811122233")
        student.messageLanguage = .hindi
        return student
    }

    /// A message logged on a day of October at 18:00.
    func entry(_ kind: MessageKind, day date: Int) -> MessageEntry {
        MessageEntry(id: UUID(), kind: kind, openedAt: india(2026, 10, date, 18, 0), language: .hindi)
    }

    var stepChapter: Chapter {
        Chapter(id: fixed("73"), subject: "Science", position: 1, name: "Chemical reactions")
    }

    var countingAtoms: Skill {
        Skill(
            id: fixed("31"), chapterID: stepChapter.id, position: 1, name: "Counting atoms in a formula",
            state: .secure, stateAt: india(2026, 9, 20), lastCheckedAt: nil
        )
    }

    var balancing: Skill {
        Skill(
            id: fixed("32"), chapterID: stepChapter.id, position: 2, name: "Balancing equations", state: .practising,
            stateAt: india(2026, 10, 1), lastCheckedAt: nil
        )
    }

    /// Dev alone in the Evening batch on Friday 9 October, at a status and a step, not on track since a day.
    func planInput(dev status: TrackStatus, step: NextStep?, since: Day? = nil) -> PlanInput {
        var student = devWithParent
        student.classID = evening.id
        student.trackStatus = status
        student.nextStep = step
        student.trackSince = since?.date(in: calendar).addingTimeInterval(3600 * 17)
        return PlanInput(
            classroom: evening, date: day(10, 9), students: [student], chapters: [student.id: [stepChapter]],
            skills: [student.id: [countingAtoms, balancing]], sessions: [], schoolItems: [],
            now: india(2026, 10, 9, 16, 35), calendar: calendar, groupCount: nil, subjects: [:]
        )
    }

    func fixed(_ tail: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-0000000000\(tail)")!
    }
}
