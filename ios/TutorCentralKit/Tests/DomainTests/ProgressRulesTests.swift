import Foundation
import Testing
@testable import Domain

/// Reports' Progress (plan/phase-15-plan.md decisions 16 and 17; Review focus 1, 4 and 9).
struct ProgressRulesTests: SchoolSamples {
    let october = Period(year: 2026, month: 10)
    let now = Day(year: 2026, month: 10, day: 7)!
    var term1of2026: Term {
        Term(schoolYear: 2026, number: 1, calendar: .standard)
    }

    let chapter = Chapter(id: UUID(), subject: "Science", position: 1, name: "Chemical reactions")

    func skill(_ state: SkillState, at date: Date, position: Int = 1, chapter: Chapter? = nil) -> Skill {
        Skill(
            id: UUID(), chapterID: (chapter ?? self.chapter).id, position: position, name: "Skill \(position)",
            state: state, stateAt: date, lastCheckedAt: nil
        )
    }

    func check(_ correct: Bool, at date: Date, placement: Bool = false, student: Student? = nil) -> CheckRecord {
        CheckRecord(
            id: UUID(), studentID: (student ?? dev).id, skillID: UUID(), sessionID: placement ? nil : UUID(),
            question: "Q", correct: correct, at: date, isPlacement: placement
        )
    }

    func session(_ day: Int, month: Int = 10, absent: Bool, student: Student? = nil) -> AttendanceSession {
        AttendanceSession(
            id: UUID(), classID: nil, date: Day(year: 2026, month: month, day: day)!, savedAt: FakeClock.oct7at1635,
            marks: [(student ?? dev).id: absent ? .absent : .present]
        )
    }

    func input(
        _ who: Student? = nil, chapters: [Chapter]? = nil, skills: [Skill] = [], checks: [CheckRecord] = [],
        sessions: [AttendanceSession] = [], span: ProgressSpan? = nil
    ) -> ProgressInput {
        ProgressInput(
            student: who ?? dev, chapters: chapters ?? [chapter], skills: skills, checks: checks, sessions: sessions,
            span: span ?? .month(october), calendar: DayHeading.india
        )
    }

    func status(_ who: Student, _ status: TrackStatus) -> Student {
        var someone = who
        someone.trackStatus = status
        return someone
    }

    func row(name: String, percent: Int?, skills: Int = 1, checks: Int = 10, status: TrackStatus = .onTrack)
        -> ProgressRow {
        ProgressRow(
            id: UUID(), name: name, initials: "XX", className: "Class 8", status: status, line: "",
            skillsSecure: skills, checks: checks, right: percent.map { $0 * checks / 100 } ?? 0, absences: 0,
            percent: percent
        )
    }

    @Test func skillsSecureCountOnlyThoseMadeSecureInTheSpan() {
        let skills = [
            skill(.secure, at: FakeClock.at(2026, 10, 2, 18, 0)), skill(.secure, at: FakeClock.at(2026, 10, 6, 18, 0)),
            skill(.secure, at: FakeClock.at(2026, 9, 28, 18, 0)), skill(
                .practising,
                at: FakeClock.at(2026, 10, 6, 18, 0)
            ),
        ]
        let made = ProgressRules.row(
            input(status(dev, .onTrack), skills: skills, checks: [check(true, at: FakeClock.oct7at1635)]),
            className: "Class 8 Science"
        )
        #expect(made.skillsSecure == 2)
    }

    @Test func rightIsRoundedAndPlacementsAreLeftOut() {
        let checks = (0 ..< 12).map { check($0 < 5, at: FakeClock.at(2026, 10, 2 + $0 % 5, 18, 0)) }
            + [
                check(false, at: FakeClock.oct7at1635, placement: true),
                check(false, at: FakeClock.oct7at1635, placement: true),
            ]
            + [check(true, at: FakeClock.at(2026, 9, 30, 18, 0))]
        let made = ProgressRules.row(input(status(dev, .watch), checks: checks), className: "Class 8 Science")
        #expect(made.right == 5 && made.checks == 12 && made.percent == 42 && made.percentText == "42%")
    }

    @Test func absencesCountTheSpansSessionsOnly() {
        let sessions = [
            session(2, absent: true),
            session(5, absent: true),
            session(6, absent: false),
            session(29, month: 9, absent: true),
        ]
        let made = ProgressRules.row(
            input(status(dev, .watch), checks: [check(true, at: FakeClock.oct7at1635)], sessions: sessions),
            className: "Class 8 Science"
        )
        #expect(made.absences == 2)
        #expect(made.line.hasSuffix("· 2 absences"))
    }

    @Test func theLineLeavesOutZeroAbsences() {
        let skills = (1 ... 3).map { skill(.secure, at: FakeClock.at(2026, 10, 2, 18, 0), position: $0) }
        let checks = (0 ..< 17).map { check($0 < 7, at: FakeClock.at(2026, 10, 3, 18, 0)) }
        let made = ProgressRules.row(
            input(status(dev, .watch), skills: skills, checks: checks),
            className: "Class 8 Science"
        )
        #expect(made.line == "3 skills secure · 41% right")
    }

    @Test func oneSkillAndOneAbsenceAreSingular() {
        let made = ProgressRules.row(input(
            status(dev, .onTrack), skills: [skill(.secure, at: FakeClock.at(2026, 10, 2, 18, 0))],
            checks: [check(true, at: FakeClock.oct7at1635)], sessions: [session(2, absent: true)]
        ), className: "Class 8 Science")
        #expect(made.line == "1 skill secure · 100% right · 1 absence")
    }

    @Test func aLadderStudentNamesTheirStepsInsteadOfSkills() {
        let areas = Ladder.Area.allCases.enumerated().map { index, area in
            Chapter(id: UUID(), subject: area.title, position: index + 1, name: area.title, ladder: area)
        }
        let reached = [2, 0, 1] // reading: Sentences; writing: still Traces; numbers: To 99
        let skills = zip(areas, reached).flatMap { area, current in
            (1 ... 5).map { skill(
                $0 <= current ? .secure : .notStarted,
                at: FakeClock.at(2026, 9, 1, 18, 0),
                position: $0,
                chapter: area
            ) }
        }
        let made = ProgressRules.row(
            input(
                status(sahil, .onTrack),
                chapters: areas,
                skills: skills,
                checks: [check(true, at: FakeClock.oct7at1635, student: sahil)]
            ),
            className: "Class 2"
        )
        #expect(made.line == "Reading: Sentences · Numbers: To 99")
    }

    @Test func aStudentWithNothingReadsNotKnownYet() {
        let made = ProgressRules.row(input(bir, chapters: []), className: "")
        #expect(made.status == .notKnown && made.line == "No checks yet" && made.percentText == "–")
    }

    @Test func aPlacedStudentReadsPlacedAndTheCount() {
        let checks = [
            check(true, at: FakeClock.oct7at1635, placement: true, student: riya),
            check(false, at: FakeClock.oct7at1635, placement: true, student: riya),
        ]
        let made = ProgressRules.row(input(riya, checks: checks), className: "Class 5")
        #expect(made.line == "Placed Wed 7 Oct · 2 checks so far")
        #expect(made.percentText == "–")
    }

    @Test func aMonthWithAttendanceAndNoChecksShowsAbsencesOnly() {
        let sessions = [session(1, absent: true), session(2, absent: true), session(5, absent: true)]
        let made = ProgressRules.row(input(status(dev, .onTrack), sessions: sessions), className: "Class 8 Science")
        #expect(made.line == "No checks yet · 3 absences" && made.percentText == "–" && made.checks == 0)
    }

    @Test func theHeroSumsTheRowsAndCountsNotOnTrack() {
        let rows = [
            row(name: "A", percent: 50, skills: 10, checks: 20, status: .notOnTrack),
            row(name: "B", percent: 90, skills: 20, checks: 20, status: .onTrack),
            row(name: "C", percent: 70, skills: 8, checks: 10, status: .notOnTrack),
            row(name: "D", percent: nil, skills: 0, checks: 0, status: .notKnown),
        ]
        let hero = ProgressRules.hero(rows, span: .month(october), now: now)
        #expect(hero.skillsSecure == 38 && hero.rightText == "70%" && hero.notOnTrack == 2)
        #expect(hero.notOnTrackLabel == "not on track")
    }

    @Test func anEndedTermsLabelSaysAtTheEnd() {
        #expect(ProgressRules.hero([], span: .term(term1of2026), now: now).notOnTrackLabel == "not on track at the end")
    }

    @Test func theHeroWithNoChecksReadsADash() {
        #expect(ProgressRules.hero([row(name: "A", percent: nil, checks: 0)], span: .month(october), now: now)
            .rightText == "–")
    }

    @Test func lowestFirstPutsTheDashLastAndTiesByName() {
        let rows = [
            row(name: "Riya", percent: nil),
            row(name: "Nikhil", percent: 50),
            row(name: "Dev", percent: 41),
            row(name: "Hemanth", percent: 50),
        ]
        #expect(ProgressRules.sorted(rows, by: .lowestFirst).map(\.name) == ["Dev", "Hemanth", "Nikhil", "Riya"])
        #expect(ProgressRules.sorted(rows, by: .highestFirst).map(\.name) == ["Hemanth", "Nikhil", "Dev", "Riya"])
        #expect(ProgressRules.sorted(rows, by: .byName).map(\.name) == ["Dev", "Hemanth", "Nikhil", "Riya"])
        #expect(ProgressSort.allCases.map(\.title) == ["Lowest first", "Highest first", "By name"])
    }

    @Test func anArchivedStudentIsNeitherListedNorSummed() {
        let rows = [
            row(name: "A", percent: 50, skills: 3, checks: 10),
            row(name: "B", percent: 100, skills: 2, checks: 10),
        ]
        let without = rows.filter { $0.name != "B" }
        #expect(ProgressRules.hero(without, span: .month(october), now: now).skillsSecure == 3)
        #expect(ProgressRules.hero(without, span: .month(october), now: now).rightText == "50%")
    }

    @Test func theSpanNamesItself() {
        #expect(ProgressSpan.month(october).title == "October 2026")
        #expect(ProgressSpan.term(term1of2026).title == "Term 1 · June to September")
        #expect(ProgressSpan.month(october).months == [october])
        #expect(!ProgressSpan.month(october).hasEnded(now))
    }

    @Test func theCSVHasTheBoardsColumnsAndTheSpansName() {
        #expect(ProgressCSV.fileName(.month(october)) == "progress-2026-10.csv")
        #expect(ProgressCSV.fileName(.term(term1of2026)) == "progress-term-1-2026.csv")
        let devRow = ProgressRow(
            id: dev.id, name: "Dev Kumar", initials: "DK", className: "Class 8 Science", status: .notOnTrack,
            line: "", skillsSecure: 3, checks: 12, right: 5, absences: 2, percent: 42
        )
        #expect(ProgressCSV.make([devRow]) == "\u{FEFF}Student,Class,Status,Skills secure,Checks,Right,Absences\r\n"
            + "Dev Kumar,Class 8 Science,Not on track,3,12,5,2\r\n")
    }
}
