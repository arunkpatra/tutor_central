import Foundation
import Testing
@testable import Domain

struct ArtefactBudgetExamTests: SchoolSamples {
    let calendar = DayHeading.india

    func line(_ day: PreparationDay, gapSkills: [String] = []) -> RevisionLine {
        RevisionLine(
            itemID: exam16.id, title: exam16.title, subject: "Science", examDate: exam16.date, day: day,
            gapSkills: gapSkills, portions: ["Chemical reactions", "Acids, bases and salts"],
            pattern: MockPattern(marks: 25, durationMinutes: 40)
        )
    }

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

    func requests(
        _ day: PreparationDay, others: [Student]? = nil, mocksMade: Set<UUID> = [],
        gapSkills: [UUID: [String]] = [:]
    ) -> [ArtefactRequest] {
        let three = [dev, meher, nikhil]
        let others = others ?? [riya, sahil]
        let revisions = Dictionary(uniqueKeysWithValues: three.map { (
            $0.id,
            line(day, gapSkills: gapSkills[$0.id] ?? [])
        ) })
        let input = PlanInput(
            classroom: evening, date: sampleToday, students: three + others, chapters: [:], skills: [:], sessions: [],
            schoolItems: [], now: FakeClock.oct7at1635, calendar: calendar, groupCount: nil, subjects: [:],
            revisions: revisions, holidays: []
        )
        let draft = PlanRules.plan(input)
        let students = Dictionary(uniqueKeysWithValues: (three + others).map { ($0.id, $0) })
        return ArtefactBudget.requests(
            for: draft, students: students, spacedSkills: [:], briefsMade: [],
            exam: ExamMaterial(revisions: revisions, mocksMade: mocksMade, gapSkills: gapSkills)
        )
    }

    @Test func anExamGroupAsksChecksASetAndASheetFromTheDaysSkillsAndNothingElse() {
        let group1 = requests(preparation[0]).filter { $0.groupNo == 1 }
        #expect(group1.map(\.kindName) == ["checks", "sheet", "sheet"])
        if case let .sheet(_, skills, _, _, _, homework) = group1[1] {
            #expect(skills == ["Spot a chemical change", "Write a word equation"] && !homework)
        }
        if case let .checks(_, skills, ids, _, _) = group1[0] {
            #expect(skills == ["Spot a chemical change", "Write a word equation"] && ids.count == 2)
        }
    }

    @Test func theMockDayAsksTheMockInTheSetsPlaceOnceOnly() {
        let mockDay = preparation[5]
        let first = requests(mockDay).filter { $0.groupNo == 1 }
        #expect(first.map(\.kindName) == ["checks", "mock"])
        if case let .mock(_, itemID, title, portions, pattern, level, subject) = first[1] {
            #expect(itemID == exam16.id && title == "Science unit test 3" && portions.count == 2)
            #expect(pattern.marks == 25 && level == .eight && subject == "Science")
        }
        let again = requests(mockDay, mocksMade: [exam16.id]).filter { $0.groupNo == 1 }
        #expect(again.map(\.kindName) == ["checks"])
    }

    @Test func theAfterMockSetComesFromTheWeakestSkills() {
        let after = preparation[6]
        let gaps = [
            dev.id: ["Balance a chemical equation", "Name the types of reactions"],
            meher.id: ["Use indicators"],
        ]
        let group1 = requests(after, gapSkills: gaps).filter { $0.groupNo == 1 }
        if case let .sheet(_, skills, _, _, _, _) = group1[1] {
            #expect(skills == ["Balance a chemical equation", "Name the types of reactions", "Use indicators"])
        }
        let none = requests(after).filter { $0.groupNo == 1 }
        if case let .sheet(_, skills, _, _, _, _) = none[1] {
            #expect(skills == ["Chemical reactions", "Acids, bases and salts"])
        }
    }

    @Test func theBudgetStillHoldsTwentyCalls() throws {
        let others = (1 ... 9).map { student("Other \($0)", level: $0 <= 5 ? .five : .two, school: nil) }
        let made = requests(preparation[5], others: others)
        #expect(made.count <= ArtefactBudget.maxCalls)
        #expect(made.contains { $0.kindName == "mock" })
        #expect(try PriceSheet.rupees(made) < 10)
    }
}
