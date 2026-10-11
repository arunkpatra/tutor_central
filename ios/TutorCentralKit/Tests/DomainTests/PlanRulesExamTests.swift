import Foundation
import Testing
@testable import Domain

struct PlanRulesExamTests: SchoolSamples {
    let calendar = DayHeading.india

    var preparation: [PreparationDay] {
        let context = PreparationContext(
            batch: evening,
            today: sampleToday,
            holidays: [],
            students: [dev],
            calendar: calendar
        )
        return ExamPreparation.days(
            exam: exam16,
            student: dev,
            chapters: devChapters,
            skills: devSkills,
            context: context
        )
    }

    var day7: PreparationDay {
        preparation[0]
    }

    var day14: PreparationDay {
        preparation[5]
    }

    var day15: PreparationDay {
        preparation[6]
    }

    func ownExam(_ student: Student, day: Int, subject: String) -> SchoolItem {
        var item = SchoolItem.fixture(
            kind: .exam, audience: .student(student.id), date: Day(year: 2026, month: 10, day: day)!,
            title: "\(subject) test", portions: "Chapter 1",
            id: UUID(uuidString: String(format: "66666666-6666-6666-6666-%012d", day))!
        )
        item.subject = subject
        return item
    }

    var riyaExam: SchoolItem {
        ownExam(riya, day: 12, subject: "Mathematics")
    }

    var meherExam: SchoolItem {
        ownExam(meher, day: 13, subject: "Mathematics")
    }

    var nikhilExam: SchoolItem {
        ownExam(nikhil, day: 15, subject: "English")
    }

    var sahilExam: SchoolItem {
        ownExam(sahil, day: 19, subject: "English")
    }

    func revisions(for students: [Student], day: PreparationDay, exam: SchoolItem? = nil) -> [UUID: RevisionLine] {
        let exam = exam ?? exam16
        let line = RevisionLine(
            itemID: exam.id, title: exam.title, subject: exam.subject ?? "Science", examDate: exam.date, day: day,
            portions: ExamPreparation.portions(exam.portions ?? ""), pattern: MockPattern(
                marks: 25,
                durationMinutes: 40
            )
        )
        return Dictionary(uniqueKeysWithValues: students.map { ($0.id, line) })
    }

    func input(
        students: [Student]? = nil, revisions: [UUID: RevisionLine] = [:], holidays: Set<UUID> = []
    ) -> PlanInput {
        PlanInput(
            classroom: evening, date: sampleToday, students: students ?? [dev, meher, nikhil, riya, sahil],
            chapters: [:], skills: [:], sessions: [], schoolItems: [], now: FakeClock.oct7at1635, calendar: calendar,
            groupCount: nil, subjects: [:], revisions: revisions, holidays: holidays
        )
    }

    /// Dev, Meher, Nikhil (class 8, Vidya), Riya (5), Sahil (2) in the Evening batch; the exam16 revision for the
    /// three.
    @Test func studentsOfOneExamFormTheirOwnGroupWithRevisionLines() {
        let draft = PlanRules.plan(input(revisions: revisions(for: [dev, meher, nikhil], day: day7)))
        let examGroup = draft.groups.first { $0.examItemID == exam16.id }
        #expect(examGroup?.number == 1 && examGroup?.subject == "Science" && examGroup?
            .chapter == "Science unit test 3")
        #expect(examGroup?.skill == "Chemical reactions · part 1 of 3")
        let devLines = draft.lines.filter { $0.studentID == dev.id }
        #expect(devLines.map(\.kind) == [.teach, .practise, .check, .homework])
        #expect(devLines.map(\.words) == [
            "Revise: Chemical reactions · part 1 of 3",
            "Revision set 1",
            "Check 3",
            "Revision sheet 1",
        ])
        #expect(!draft.lines.contains { $0.groupNo == 1 && [.workedExample, .figure, .brief].contains($0.kind) })
        #expect(draft.groups.count == 3) // the exam group, then Riya and Sahil by level
    }

    @Test func twoExamsInOneBatchMakeTwoExamGroupsAndOneLevelGroup() {
        var revs = revisions(for: [dev, meher], day: day7)
        revs.merge(revisions(for: [riya], day: day7, exam: riyaExam)) { first, _ in first }
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 2)
        #expect(draft.groups.last?.memberIDs.sorted() == [nikhil.id, sahil.id].sorted())
    }

    @Test func aThirdExamKeepsItsStudentsInTheirLevelGroup() {
        var revs = revisions(for: [dev], day: day7)
        revs.merge(revisions(for: [riya], day: day7, exam: riyaExam)) { first, _ in first }
        revs.merge(revisions(for: [sahil], day: day7, exam: sahilExam)) { first, _ in first }
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 2)
        let sahilLines = draft.lines.filter { $0.studentID == sahil.id }
        #expect(sahilLines.first?.words.hasPrefix("Revise: ") == true) // his own words, the group's material
    }

    @Test func aBatchOfExamStudentsOnlyMayHaveThreeExamGroups() {
        var revs = revisions(for: [dev], day: day7)
        revs.merge(revisions(for: [meher], day: day7, exam: meherExam)) { first, _ in first }
        revs.merge(revisions(for: [nikhil], day: day7, exam: nikhilExam)) { first, _ in first }
        let draft = PlanRules.plan(input(students: [dev, meher, nikhil], revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 3)
    }

    @Test func theMockDayHasTheMockForPractiseAndNoHomework() {
        let draft = PlanRules.plan(input(revisions: revisions(for: [dev, meher, nikhil], day: day14)))
        let devLines = draft.lines.filter { $0.studentID == dev.id }
        #expect(devLines.map(\.kind) == [.teach, .practise, .check])
        #expect(devLines[0].words == "The mock · 25 marks · 40 minutes" && devLines[1].words == "The mock")
    }

    @Test func theDayAfterTheMockTakesTheGapReportsLineWhenOneWasUsed() {
        var revs = revisions(for: [dev, meher, nikhil], day: day15)
        revs[dev.id] = RevisionLine(
            itemID: exam16.id,
            title: "Science unit test 3",
            subject: "Science",
            examDate: exam16.date,
            day: day15,
            gapLine: "Balancing equations: the worked example, then a set of 6",
            gapSkills: ["Balance a chemical equation"]
        )
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.lines.first { $0.studentID == dev.id && $0.kind == .teach }?
            .words == "Balancing equations: the worked example, then a set of 6")
        #expect(draft.lines.first { $0.studentID == meher.id && $0.kind == .teach }?
            .words == "Revise: what the mock showed")
    }

    @Test func aStudentOnHolidayIsLeftOut() {
        let draft = PlanRules.plan(input(holidays: [riya.id]))
        #expect(draft.leftOut == [riya.id] && !draft.lines.contains { $0.studentID == riya.id })
    }

    @Test func aLinesWordsAreCutAtAWordAtTwoHundred() {
        let long = "Revise: " + String(repeating: "Acids ", count: 50)
        let cut = PlanRules.cut(long)
        #expect(cut.storedCount <= 200 && !cut.hasSuffix(" ") && !cut.hasSuffix("·"))
    }
}
