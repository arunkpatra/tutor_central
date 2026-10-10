import Foundation
import Testing
@testable import Domain

struct PlanRulesTests {
    let calendar = DayHeading.india
    let evening = Classroom(
        id: UUID(),
        name: "Evening batch",
        subject: "Science",
        monthlyFee: nil,
        meetingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
        startTime: TimeOfDay(hour: 17, minute: 0),
        endTime: TimeOfDay(hour: 18, minute: 30),
        archivedAt: nil
    )

    func student(
        _ name: String,
        class level: ClassLevel?,
        status: TrackStatus = .onTrack,
        gender: Gender? = nil
    ) -> Student {
        Student(
            id: UUID(),
            name: name,
            classID: evening.id,
            monthlyFee: nil,
            parentName: nil,
            parentPhone: nil,
            dateOfBirth: nil,
            gender: gender,
            notes: nil,
            archivedAt: nil,
            thisMonth: nil,
            classLevel: level,
            trackStatus: status
        )
    }

    /// A Science book of three chapters, the first `taught` chapters practising, for a student.
    func science(_ pupil: Student, taught: Int) -> (chapters: [Chapter], skills: [Skill]) {
        let chapters = (1 ... 3).map { chapter($0, subject: "Science") }
        let skills = chapters.flatMap { c in (1 ... 2).map { skill(
            c,
            $0,
            state: c.position <= taught ? .practising : .notStarted,
            stateAt: FakeClock.at(2026, 10, 7 - c.position, 17, 0),
            name: "Science \(c.position).\($0)"
        ) } }
        return (chapters, skills)
    }

    func input(
        _ students: [Student],
        books: [UUID: (chapters: [Chapter], skills: [Skill])],
        sessions: [AttendanceSession] = [],
        groupCount: Int? = nil,
        subjects: [Int: String] = [:],
        classroom: Classroom? = nil
    ) -> PlanInput {
        PlanInput(
            classroom: classroom ?? evening,
            date: Day(iso: "2026-10-07")!,
            students: students,
            chapters: books.mapValues(\.chapters),
            skills: books.mapValues(\.skills),
            sessions: sessions,
            schoolItems: [],
            now: FakeClock.oct7at1635,
            calendar: calendar,
            groupCount: groupCount,
            subjects: subjects
        )
    }

    @Test func threeLevelsMakeThreeGroupsLargestFirst() {
        let dev = student("Dev", class: .eight), meher = student("Meher", class: .eight), nikhil = student(
            "Nikhil",
            class: .eight
        )
        let riya = student("Riya", class: .five), sahil = student("Sahil", class: .two)
        let books = Dictionary(uniqueKeysWithValues: [dev, meher, nikhil].map { ($0.id, science($0, taught: 2)) })
        let draft = PlanRules.plan(input([riya, sahil, dev, meher, nikhil], books: books))
        #expect(draft.groups.map(\.number) == [1, 2, 3])
        #expect(draft.groups[0].memberIDs == [dev.id, meher.id, nikhil.id])
        #expect(draft.groups[0].classLevels == [.eight])
        #expect(draft.groups[1].memberIDs == [riya.id])
        #expect(draft.groups[2].memberIDs == [sahil.id])
    }

    @Test func aKeptGroupCountCutsAtTheLargestGaps() {
        let students = [
            student("A", class: .eight),
            student("B", class: .seven),
            student("C", class: .three),
            student("D", class: .two),
        ]
        let two = PlanRules.plan(input(students, books: [:], groupCount: 2))
        #expect(two.groups.count == 2)
        #expect(Set(two.groups[0].memberIDs) == Set(students.prefix(2).map(\.id)))
        let one = PlanRules.plan(input(students, books: [:], groupCount: 1))
        #expect(one.groups.count == 1)
        #expect(one.groups[0].memberIDs.count == 4)
    }

    @Test func aStudentNotOnTrackSitsOneLevelDown() throws {
        let ann = student("A", class: .eight), ben = student("B", class: .eight, status: .notOnTrack), cai = student(
            "C",
            class: .seven
        )
        let draft = PlanRules.plan(input([ann, ben, cai], books: [:], groupCount: 2))
        let withB = try #require(draft.groups.first { $0.memberIDs.contains(ben.id) })
        #expect(withB.memberIDs.contains(cai.id))
        #expect(!withB.memberIDs.contains(ann.id))
    }

    @Test func aBatchOfOneHasOneGroup() {
        let dev = student("Dev", class: .eight)
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.groups.count == 1)
        #expect(draft.lines.filter { $0.studentID == dev.id }.map(\.kind) == [.teach, .practise, .check, .homework])
    }

    @Test func theTeachLineIsTheFirstSkillNotSecureAndTheGroupTakesItsChapter() {
        let dev = student("Dev", class: .eight)
        let book = science(dev, taught: 2)
        let draft = PlanRules.plan(input([dev], books: [dev.id: book]))
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach: Science 1.1")
        #expect(draft.groups[0].chapter == "Chapter 1")
        #expect(draft.groups[0].skill == "Science 1.1")
        #expect(draft.groups[0].skillID == book.skills[0].id)
    }

    @Test func watchAndNotOnTrackTeachAgainWithTheWorkedExample() {
        let dev = student("Dev", class: .eight, status: .watch)
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach again: Science 1.1, with the worked example")
        #expect(draft.lines.first { $0.kind == .check }?.personalChecks == true)
    }

    @Test func twoAbsencesRunningAddACatchUpLineBeforeTheTeachLine() throws {
        let dev = student("Dev", class: .eight)
        let mon = try AttendanceSession(
            id: UUID(),
            classID: evening.id,
            date: #require(Day(iso: "2026-10-05")),
            savedAt: FakeClock.oct7at1635,
            marks: [dev.id: .absent]
        )
        let tue = try AttendanceSession(
            id: UUID(),
            classID: evening.id,
            date: #require(Day(iso: "2026-10-06")),
            savedAt: FakeClock.oct7at1635,
            marks: [dev.id: .absent]
        )
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)], sessions: [mon, tue]))
        let devs = draft.lines.filter { $0.studentID == dev.id }
        #expect(devs.map(\.kind) == [.catchUp, .teach, .practise, .check, .homework])
        #expect(devs[0].words == "Catch up: missed Mon and Tue · then Science 1.1")
        #expect(devs[3].personalChecks)
    }

    @Test func nothingTaughtYetMakesAPlacementLineWithThePronoun() {
        let riya = student("Riya", class: .five, gender: .female)
        let book = science(riya, taught: 0)
        let draft = PlanRules.plan(input([riya], books: [riya.id: book]))
        #expect(draft.lines.first { $0.kind == .check }?.words == "Placement, her first checks")
        #expect(draft.lines.first { $0.kind == .check }?.personalChecks == true)
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach: Science 1.1")
    }

    @Test func theSubjectIsTheLeastRecentlyTaughtUnlessTheWeekdayPatternSaysAnother() {
        let dev = student("Dev", class: .eight)
        let science = science(dev, taught: 2)
        let mathsChapter = chapter(1, subject: "Mathematics")
        let september = FakeClock.at(2026, 9, 20, 17, 0)
        let mathsSkill = skill(mathsChapter, 1, state: .practising, stateAt: september, name: "Maths 1.1")
        let maths = (chapters: [mathsChapter], skills: [mathsSkill])
        let book = (chapters: science.chapters + maths.chapters, skills: science.skills + maths.skills)
        let draft = PlanRules.plan(input([dev], books: [dev.id: book]))
        #expect(draft.groups[0].subject == "Mathematics")
        var patterned = evening
        patterned.planPattern = [.wednesday: PlanPattern(groups: 1, subjects: ["Science"])]
        let kept = PlanRules.plan(input([dev], books: [dev.id: book], classroom: patterned))
        #expect(kept.groups[0].subject == "Science")
        let chosen = PlanRules.plan(input([dev], books: [dev.id: book], subjects: [1: "Science"]))
        #expect(chosen.groups[0].subject == "Science")
    }

    @Test func aSubjectNeverTaughtComesBeforeOneTaughtLongAgo() {
        let dev = student("Dev", class: .eight)
        let science = science(dev, taught: 1)
        let english = chapter(1, subject: "English")
        let book = (
            chapters: science.chapters + [english],
            skills: science.skills + [skill(english, 1, name: "English 1.1")]
        )
        #expect(PlanRules.plan(input([dev], books: [dev.id: book])).groups[0].subject == "English")
    }

    @Test func theGroupsSubjectIsTheMostCommonAndEveryLineFollowsIt() {
        let ann = student("A", class: .eight), ben = student("B", class: .eight), cai = student("C", class: .eight)
        let maths = chapter(1, subject: "Mathematics")
        let scienceBook = { (pupil: Student) in science(pupil, taught: 1) }
        let mathsBook = (chapters: [maths], skills: [skill(maths, 1, name: "Maths 1.1")])
        let draft = PlanRules.plan(input(
            [ann, ben, cai],
            books: [ann.id: scienceBook(ann), ben.id: scienceBook(ben), cai.id: mathsBook]
        ))
        #expect(draft.groups[0].subject == "Science")
        #expect(draft.lines.first { $0.studentID == cai.id && $0.kind == .teach }?.words == "Teach: Science 1.1")
    }

    @Test func aBatchWithNoRecordIsPlannedByClass() {
        let ann = student("A", class: .eight), ben = student("B", class: .five)
        let draft = PlanRules.plan(input([ann, ben], books: [:]))
        #expect(draft.groups.count == 2)
        #expect(draft.groups.allSatisfy { $0.skill.isEmpty && $0.chapter.isEmpty && $0.skillID == nil })
        #expect(draft.groups[0].subject == "Science")
        #expect(draft.lines.filter { $0.kind == .teach }.allSatisfy { $0.words == "Teach: with the group" })
    }

    @Test func aStudentWithNoClassFollowsTheGroup() {
        let dev = student("Dev", class: .eight), bir = student("Bir", class: nil)
        let draft = PlanRules.plan(input([dev, bir], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.groups.count == 1)
        #expect(draft.lines.first { $0.studentID == bir.id && $0.kind == .teach }?.words == "Teach: Science 1.1")
        #expect(draft.lines.first { $0.studentID == bir.id && $0.kind == .check }?.personalChecks == false)
    }

    @Test func homeworkIsLightUpToClassFive() {
        #expect(PlanRules.homeworkWords(.five) == "Homework sheet 1, light")
        #expect(PlanRules.homeworkWords(.six) == "Homework sheet 1")
        #expect(PlanRules.homeworkWords(nil) == "Homework sheet 1")
    }

    @Test func aBriefLineComesForAGroupAboveClassSeven() {
        let dev = student("Dev", class: .eight), riya = student("Riya", class: .five)
        let draft = PlanRules.plan(input(
            [dev, riya],
            books: [dev.id: science(dev, taught: 1), riya.id: science(riya, taught: 1)]
        ))
        let briefs = draft.lines.filter { $0.kind == .brief }
        #expect(briefs.count == 1)
        #expect(briefs[0].groupNo == draft.groups.first { $0.memberIDs == [dev.id] }?.number)
        #expect(briefs[0].words == "Your brief · Chapter 1")
    }

    @Test func aStudentIsNeverInTwoGroupsAndEveryoneIsPlaced() {
        let students = (1 ... 12).map { student("S\($0)", class: ClassLevel.allCases[$0 % 12]) }
        let draft = PlanRules.plan(input(students, books: [:]))
        let placed = draft.groups.flatMap(\.memberIDs)
        #expect(Set(placed).count == 12)
        #expect(placed.count == 12)
        #expect(draft.groups.count == 3)
    }
}
