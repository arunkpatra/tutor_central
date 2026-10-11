import Foundation
import Testing
@testable import Domain

/// Make's target and its rules (plan/phase-15-plan.md decisions 2, 3 and 6; Review focus 1 and 2).
struct MakeRulesTests: SchoolSamples {
    let plan = UUID(uuidString: "99999999-9999-9999-9999-999999999991")!

    var devBook: MakeBook {
        MakeBook(chapters: devChapters, skills: devSkills)
    }

    func classmate(_ name: String, level: ClassLevel?) -> Student {
        var someone = student(name, level: level, school: vidya.id)
        someone.classID = evening.id
        return someone
    }

    var groupOne: TodayGroup {
        TodayGroup(planID: plan, classID: evening.id, group: PlanGroup(
            number: 1, subject: "Science", chapter: "Chemical reactions", skill: "Balancing equations",
            classLevels: [.eight], memberIDs: [dev.id, meher.id, nikhil.id], skillID: nil
        ))
    }

    @Test func aStudentWithNoBookHasNoSkillsAndNoLevel() {
        let roster = MakeRoster(students: [bir], classes: [], groups: [])
        #expect(MakeRules.level(for: .student(bir.id), roster: roster) == nil)
        #expect(MakeRules.skills(for: .student(bir.id), subject: "Mathematics", books: [:], roster: roster) == [])
    }

    @Test func aStudentsSkillIsTheirCurrentOneInTheSubject() {
        let roster = MakeRoster(students: [dev], classes: [], groups: [])
        #expect(MakeRules.skills(for: .student(dev.id), subject: "Science", books: [dev.id: devBook], roster: roster)
            == ["Balance a chemical equation"])
        #expect(MakeRules.skills(
            for: .student(dev.id),
            subject: "Mathematics",
            books: [dev.id: devBook],
            roster: roster
        )
            == [])
        #expect(MakeRules.level(for: .student(dev.id), roster: roster) == .eight)
    }

    @Test func aStudentsSubjectsAreTheirBooksInOrder() {
        let roster = MakeRoster(students: [dev], classes: [], groups: [])
        #expect(MakeRules.subjects(for: .student(dev.id), books: [dev.id: devBook], roster: roster) == ["Science"])
    }

    @Test func aGroupAcrossLevelsIsMadeAtItsHighestLevel() {
        let group = TodayGroup(planID: plan, classID: evening.id, group: PlanGroup(
            number: 2, subject: "Mathematics", chapter: "Parts and wholes", skill: "Fractions on a bar",
            classLevels: [.two, .five], memberIDs: [sahil.id, riya.id], skillID: nil
        ))
        let roster = MakeRoster(students: [sahil, riya], classes: [evening], groups: [group])
        #expect(MakeRules.level(for: .group(plan: plan, number: 2), roster: roster) == .five)
        #expect(MakeRules.skills(for: .group(plan: plan, number: 2), subject: "Mathematics", books: [:], roster: roster)
            == ["Fractions on a bar"])
        #expect(MakeRules.subjects(for: .group(plan: plan, number: 2), books: [:], roster: roster) == ["Mathematics"])
    }

    @Test func aBatchTakesItsMostCommonLevelAndItsMembersCurrentSkills() {
        let eights = (1 ... 3).map { classmate("Eight \($0)", level: .eight) }
        let fives = (1 ... 2).map { classmate("Five \($0)", level: .five) }
        let book = MakeBook(chapters: devChapters, skills: devSkills)
        var books = Dictionary(uniqueKeysWithValues: eights.map { ($0.id, book) })
        let other = MakeBook(chapters: devChapters, skills: devSkills.map { skill in
            var moved = skill
            moved.state = skill.position == 3 && skill.chapterID == devChapters[0].id ? .secure : skill.state
            return moved
        })
        books[fives[0].id] = other
        let roster = MakeRoster(students: eights + fives, classes: [evening], groups: [])
        #expect(MakeRules.level(for: .batch(evening.id), roster: roster) == .eight)
        #expect(MakeRules.skills(for: .batch(evening.id), subject: "Science", books: books, roster: roster)
            == ["Balance a chemical equation", "Name the types of reactions"])
    }

    @Test func aBatchTiedBetweenTwoLevelsTakesTheHigher() {
        let roster = MakeRoster(
            students: [classmate("A", level: .five), classmate("B", level: .eight)], classes: [evening], groups: []
        )
        #expect(MakeRules.level(for: .batch(evening.id), roster: roster) == .eight)
    }

    @Test func aBatchsSkillsStopAtSix() {
        let many = (1 ... 8).map { classmate("S\($0)", level: .eight) }
        let books = Dictionary(uniqueKeysWithValues: many.enumerated().map { index, someone in
            let chapter = Chapter(id: UUID(), subject: "Science", position: 1, name: "C")
            let skill = Skill(
                id: UUID(), chapterID: chapter.id, position: 1, name: "Skill \(index)", state: .taught,
                stateAt: FakeClock.oct7at1635, lastCheckedAt: nil
            )
            return (someone.id, MakeBook(chapters: [chapter], skills: [skill]))
        })
        let roster = MakeRoster(students: many, classes: [evening], groups: [])
        #expect(MakeRules.skills(for: .batch(evening.id), subject: "Science", books: books, roster: roster).count == 6)
    }

    @Test func aClassLevelSendsNoSkills() {
        let roster = MakeRoster(students: [], classes: [], groups: [])
        #expect(MakeRules.skills(for: .classLevel(.eight), subject: "Science", books: [:], roster: roster) == [])
        #expect(MakeRules.level(for: .classLevel(.eight), roster: roster) == .eight)
    }

    @Test func theForWordsNameTheTarget() {
        let members = [dev, meher, nikhil].map { someone in
            var member = someone
            member.classID = evening.id
            return member
        }
        let roster = MakeRoster(students: members, classes: [evening], groups: [groupOne])
        #expect(MakeRules.forWords(.student(dev.id), roster: roster, subject: "Science", skill: "Balancing equations")
            == MakeFor(target: .student(dev.id), title: "For Dev", line: "Class 8 Science · Balancing equations"))
        #expect(MakeRules.forWords(.group(plan: plan, number: 1), roster: roster, subject: "Science", skill: nil)
            == MakeFor(target: .group(plan: plan, number: 1), title: "Group 1", line: "Class 8 Science"))
        #expect(MakeRules.forWords(.batch(evening.id), roster: roster, subject: "Science", skill: nil)
            == MakeFor(target: .batch(evening.id), title: "Evening batch", line: "Class 8 · Science"))
        let level = MakeRules.forWords(.classLevel(.eight), roster: roster, subject: "Science", skill: nil)
        #expect(level.title == "Class 8" && level.line == "Science")
        #expect(level.eyebrow == "Class 8 · Science")
    }

    @Test func theFormsChoicesAreTheBoards() {
        #expect(MakeRules.sheetLengths.map(\.questions) == [6, 10, 15])
        #expect(MakeRules.sheetLengths.map(\.title) == ["Short", "Medium", "Long"])
        #expect(MakeRules.levels.map(\.reason) == ["easier", nil, "harder"])
        #expect(MakeRules.tutorSaysLimit == 300)
    }

    @Test func aTargetAndItsWordsRoundTripAsTheContentKeepsThem() throws {
        let targets: [MakeTarget] = [
            .student(dev.id), .group(plan: plan, number: 2), .batch(evening.id), .classLevel(.ukg),
        ]
        for target in targets {
            let made = MakeFor(target: target, title: "T", line: "L")
            let json = try JSONEncoder().encode(made)
            #expect(try JSONDecoder().decode(MakeFor.self, from: json) == made)
        }
    }
}
