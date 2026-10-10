import Foundation
import Testing
@testable import Domain

struct ArtefactBudgetTests {
    struct Built {
        let draft: PlanDraft
        let students: [UUID: Student]
        let spaced: [UUID: [Skill]]
    }

    /// A draft of students in groups by class, each with a Science book whose first chapter has two secure skills and a
    /// third practising (the teach skill, `skillName` when given); `books: false` gives them none.
    func draft(
        _ levels: [ClassLevel], statuses: [TrackStatus] = [], skillName: String? = nil, books: Bool = true
    ) -> Built {
        let calendar = DayHeading.india
        let classroom = Classroom(
            id: UUID(), name: "Evening batch", subject: "Science", monthlyFee: nil, meetingDays: [.wednesday],
            startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 30), archivedAt: nil
        )
        let students = levels.enumerated().map { index, level in
            Student(
                id: UUID(), name: String(format: "S%02d", index + 1), classID: classroom.id, monthlyFee: nil,
                parentName: nil, parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil,
                thisMonth: nil, classLevel: level, trackStatus: index < statuses.count ? statuses[index] : .onTrack
            )
        }
        var chapters: [UUID: [Chapter]] = [:]
        var skills: [UUID: [Skill]] = [:]
        for student in students where books {
            let first = chapter(1, subject: "Science")
            chapters[student.id] = [first, chapter(2, subject: "Science")]
            skills[student.id] = [
                skill(first, 1, state: .secure, stateAt: FakeClock.at(2026, 9, 20, 17, 0), name: "Science 1.1"),
                skill(first, 2, state: .secure, stateAt: FakeClock.at(2026, 9, 25, 17, 0), name: "Science 1.2"),
                skill(
                    first,
                    3,
                    state: .practising,
                    stateAt: FakeClock.at(2026, 10, 5, 17, 0),
                    name: skillName ?? "Science 1.3"
                ),
            ]
        }
        let input = PlanInput(
            classroom: classroom, date: Day(FakeClock.oct7at1635, calendar: calendar), students: students,
            chapters: chapters, skills: skills, sessions: [], schoolItems: [], now: FakeClock.oct7at1635,
            calendar: calendar, groupCount: nil, subjects: [:]
        )
        let spaced = Dictionary(uniqueKeysWithValues: skills.map { id, list in
            (
                id,
                SpacedQueue.pick(
                    skills: list,
                    chapters: chapters[id] ?? [],
                    now: FakeClock.oct7at1635,
                    calendar: calendar
                )
            )
        })
        return Built(
            draft: PlanRules.plan(input), students: Dictionary(uniqueKeysWithValues: students.map { ($0.id, $0) }),
            spaced: spaced
        )
    }

    @Test func threeGroupsOfOneGetTheGroupsSixKindsAtMost() {
        let built = draft([.eight, .five, .two])
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        let group1 = requests.filter { $0.groupNo == 1 }
        #expect(group1.map(\.kindName) == [
            "checks",
            "sheet",
            "sheet",
            "workedExample",
            "brief",
        ]) // no figure: the skill names none
        #expect(requests.filter { $0.groupNo == 3 }.map(\.kindName) == ["checks", "sheet", "sheet", "workedExample"])
    }

    @Test func aTwelveStudentBatchCostsWhatThreeGroupsCostPlusPersonalChecks() {
        let twelve = draft(
            Array(repeating: .eight, count: 4) + Array(repeating: .five, count: 4) + Array(repeating: .two, count: 4),
            statuses: [.watch, .notOnTrack]
        )
        let three = draft([.eight, .five, .two])
        let big = ArtefactBudget.requests(
            for: twelve.draft,
            students: twelve.students,
            spacedSkills: twelve.spaced,
            briefsMade: []
        )
        let small = ArtefactBudget.requests(
            for: three.draft,
            students: three.students,
            spacedSkills: three.spaced,
            briefsMade: []
        )
        let personal = big.filter {
            if case .personalChecks = $0 {
                true
            } else {
                false
            }
        }
        #expect(big.count - personal.count == small.count)
        #expect(personal.count == 2)
        #expect(PriceSheet.rupees(big) < 10)
    }

    @Test func personalChecksAreCappedAtFourAndTheRestTakeTheGroups() {
        let built = draft(
            Array(repeating: .eight, count: 8),
            statuses: Array(repeating: .watch, count: 8)
        )
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.filter {
            if case .personalChecks = $0 {
                true
            } else {
                false
            }
        }.count == 4)
    }

    @Test func theOrderIsChecksFirstThenTheSetTheSheetTheExampleTheFigureTheBrief() {
        let built = draft([.eight])
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(
            for: plan,
            students: students,
            spacedSkills: spaced,
            briefsMade: ["Chapter 1"]
        )
        #expect(requests.map(\.kindName) == ["checks", "sheet", "sheet", "workedExample", "brief"])
        if case let .sheet(_, _, _, _, questions, forHomework) = requests[1] {
            #expect(questions == 10); #expect(!forHomework)
        }
        if case let .sheet(_, _, _, _, questions, forHomework) = requests[2] {
            #expect(questions == 10); #expect(forHomework)
        }
    }

    @Test func homeworkIsFiveQuestionsUpToClassFive() {
        let built = draft([.five])
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        if case let .sheet(_, _, _, _, questions, true) = requests[2] {
            #expect(questions == 5)
        } else {
            Issue.record("no homework sheet")
        }
    }

    @Test func aFigureComesWhenTheSkillNamesATemplate() {
        let built = draft([.five], skillName: "Compare simple fractions")
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.contains {
            if case .figure(_, .fractionBar, _, _, _) = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func theBriefComesAboveClassSevenOrWhenAskedBefore() {
        let young = draft([.five])
        #expect(!ArtefactBudget.requests(
            for: young.draft,
            students: young.students,
            spacedSkills: young.spaced,
            briefsMade: []
        ).contains {
            if case .brief = $0 {
                true
            } else {
                false
            }
        })
        #expect(ArtefactBudget.requests(
            for: young.draft,
            students: young.students,
            spacedSkills: young.spaced,
            briefsMade: ["Chapter 1"]
        ).contains {
            if case .brief = $0 {
                true
            } else {
                false
            }
        })
    }

    @Test func theGroupsChecksAreTodaysSkillAndTwoSpacedOnes() {
        let built = draft([.eight, .eight, .eight])
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        guard case let .checks(_, skills, ids, _, _) = requests[0] else { Issue.record("no group checks"); return }
        #expect(skills.count == 3)
        #expect(skills[0] == plan.groups[0].skill)
        #expect(Set(skills).count == 3)
        #expect(ids.count == 3)
    }

    @Test func aGroupWithoutASkillGetsNoChecksUntilItIsNamed() {
        let built = draft([.eight], books: false)
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.isEmpty) // the maker names the skill through /ai/plan, then asks again with the named draft
    }

    @Test func nothingPersonalIsEverMade() {
        let built = draft(
            Array(repeating: .eight, count: 12),
            statuses: Array(repeating: .notOnTrack, count: 12)
        )
        let (plan, students, spaced) = (built.draft, built.students, built.spaced)
        let requests = ArtefactBudget.requests(for: plan, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.count <= ArtefactBudget.maxCalls)
        for request in requests {
            switch request {
            case .personalChecks, .placement: break // named by id for the link, never sent: the maker sends skills only
            case .checks, .sheet, .workedExample, .figure, .brief: #expect(request.studentID == nil)
            }
        }
    }
}

extension ArtefactRequest {
    var kindName: String {
        switch self {
        case .checks: "checks"
        case .personalChecks: "personalChecks"
        case .placement: "placement"
        case .sheet: "sheet"
        case .workedExample: "workedExample"
        case .figure: "figure"
        case .brief: "brief"
        }
    }

    var studentID: UUID? {
        switch self {
        case let .personalChecks(id, _, _, _, _), let .placement(id, _): id
        default: nil
        }
    }
}
