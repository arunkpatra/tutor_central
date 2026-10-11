import Data
import Domain
import Foundation
import Testing
@testable import Today

/// The plan in exam mode (plan/phase-13-plan.md decisions 10 to 12, 17): exam groups, revision lines, the mock made
/// once, holidays.
@MainActor struct PlanMakerExamTests {
    /// Science unit test 3 for class 8 at Vidya Niketan on Friday 16 (Dev, Meher, Nikhil), shared on Wednesday 7.
    var exam16: SchoolItem {
        FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }!
    }

    var examIn20Days: SchoolItem {
        var item = exam16
        item.date = FakeSchoolItemsRepository.day(27)
        return item
    }

    func holiday(for audience: ItemAudience) -> SchoolItem {
        var item = FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.dasara }!
        item.audience = audience
        item.date = PlanTest.wednesday
        item.endDate = nil
        return item
    }

    /// Dev's gap report for the exam, used: its first day's line is Thursday 15's.
    var devGapReportUsed: Artefact {
        let content = GapReportContent(
            summary: "Balancing needs the last day.", bySkill: [],
            days: [
                GapReportContent.DayPlan(
                    title: "Thursday", line: "Balancing equations: the worked example, then a set of 6"
                ),
            ],
            usedAt: PlanTest.at(14, 19, 0), score: 31, max: 40, schoolItemID: exam16.id
        )
        return Artefact(
            id: UUID(), kind: .gapReport, source: .made, title: "What the mock showed", content: .gapReport(content),
            photoPath: nil, studentID: FakeStudentsRepository.dev, planID: nil, regeneratedFrom: nil,
            madeAt: PlanTest.at(14, 18, 50), generationID: nil, schoolItemID: exam16.id
        )
    }

    func teach(_ draft: PlanDraft, _ student: UUID) -> String? {
        draft.lines.first { $0.studentID == student && $0.kind == .teach }?.words
    }

    @Test func anExamInTheWindowTurnsItsStudentsLinesToRevision() async throws {
        let maker = PlanTest.maker(plans: FakePlansRepository(), items: [exam16])
        let draft = try await maker.draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(draft.groups[0].examItemID == exam16.id)
        #expect(teach(draft, FakeStudentsRepository.dev)?.hasPrefix("Revise: ") == true)
    }

    @Test func anExamOutsideTheWindowChangesNothing() async throws {
        let maker = PlanTest.maker(plans: FakePlansRepository(), items: [examIn20Days])
        let draft = try await maker.draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(draft.groups.allSatisfy { $0.examItemID == nil })
    }

    @Test func theMockIsMadeOnceForTheExamAndLinkedAgainTheNextTime() async throws {
        let ai = FakeAIRepository(), plans = FakePlansRepository()
        let wednesday14 = FakeSchoolItemsRepository.day(14)
        let maker = PlanTest.maker(plans: plans, ai: ai, now: PlanTest.at(14, 16, 35), items: [exam16])
        let batch = PlanTest.batch(PlanTest.members, on: wednesday14)
        await maker.make(batch, choices: nil) { _ in }
        #expect(ai.mockCalls.count == 1 && plans.artefacts.filter { $0.kind == .mock }.count == 1)
        #expect(plans.artefacts.first { $0.kind == .mock }?.schoolItemID == exam16.id)
        await maker.make(batch, choices: nil) { _ in } // Make the plan again
        #expect(ai.mockCalls.count == 1)
        let plan = try #require(try await plans.plan(
            centre: PlanTest.centre,
            classID: PlanTest.evening.id,
            date: wednesday14
        ))
        #expect(plan.artefact(group: 1, kind: .mock) != nil)
    }

    @Test func aStudentOnHolidayIsLeftOutAndAWholeBatchOnHolidayMakesNoPlan() async throws {
        let vidya = FakeSchoolsRepository.vidya.id
        let classEight = holiday(for: .schoolClass(school: vidya, level: .eight))
        let maker = PlanTest.maker(plans: FakePlansRepository(), items: [classEight])
        let draft = try await maker.draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(Set(draft.leftOut) == [
            FakeStudentsRepository.dev,
            FakeStudentsRepository.meher,
            FakeStudentsRepository.nikhil,
        ])
        #expect(await !maker.wholeBatchOnHoliday(PlanTest.batch(PlanTest.members)))
        let all = PlanTest.maker(plans: FakePlansRepository(), items: [
            holiday(for: .school(vidya)), holiday(for: .student(FakeStudentsRepository.sahil)),
        ])
        #expect(await all.wholeBatchOnHoliday(PlanTest.batch(PlanTest.members)))
    }

    @Test func aUsedGapReportGivesTheDayAfterTheMockItsLines() async throws {
        let plans = FakePlansRepository(artefacts: [devGapReportUsed])
        let thursday15 = FakeSchoolItemsRepository.day(15)
        let maker = PlanTest.maker(plans: plans, now: PlanTest.at(15, 16, 35), items: [exam16])
        let draft = try await maker.draft(PlanTest.batch(PlanTest.members, on: thursday15), choices: nil)
        #expect(teach(draft, FakeStudentsRepository.dev) == "Balancing equations: the worked example, then a set of 6")
        #expect(teach(draft, FakeStudentsRepository.meher) == "Revise: what the mock showed")
    }

    @Test func aChecksSkillIsMatchedByNameBeforeTheAnswersOrder() {
        let (idA, idB) = (UUID(), UUID())
        let questions = [
            CheckQuestion(skill: "B", question: "q", answer: "a"),
            CheckQuestion(skill: "A", question: "q", answer: "a"),
        ]
        let content = PlanMaker.checks(questions, skills: [("A", idA), ("B", idB)], placement: false)
        guard case let .check(checks) = content else {
            Issue.record("not checks")
            return
        }
        #expect(checks.questions.map(\.skillID) == [idB, idA])
    }
}
