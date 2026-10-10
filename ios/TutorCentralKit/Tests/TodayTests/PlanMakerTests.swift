import Data
import Domain
import Foundation
import Testing
@testable import Today

/// The plan made on the phone (plan decisions 1 to 6): the rules, the write, then the material in the budget's order.
@MainActor struct PlanMakerTests {
    func plan(_ plans: FakePlansRepository) async throws -> PlanRecord {
        try #require(try await plans.plan(
            centre: PlanTest.centre,
            classID: PlanTest.evening.id,
            date: PlanTest.wednesday
        ))
    }

    @Test func theEveningBatchMakesThreeGroupsWithTheirMaterialInOrder() async throws {
        let plans = FakePlansRepository(), ai = FakeAIRepository()
        let maker = PlanTest.maker(plans: plans, ai: ai)
        let seen = Seen()
        await maker.make(PlanTest.batch(PlanTest.members), choices: nil) { progress in await seen.add(progress.name) }
        #expect(seen.names.first == "written")
        #expect(seen.names.last == "finished")
        let plan = try await plan(plans)
        #expect(plan.groups.map(\.number) == [1, 2, 3])
        #expect(plan.artefact(group: 1, kind: .check) != nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: false) != nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
        #expect(plan.artefact(group: 1, kind: .workedExample) != nil)
        #expect(plan.artefact(group: 1, kind: .brief) != nil) // class 8 is above 7
        let sahils = try #require(plan.groups.first { $0.memberIDs.contains(FakeStudentsRepository.sahil) })
        #expect(plan.artefact(group: sahils.number, kind: .brief) == nil)
        #expect(ai.sheets.count == 6)
        #expect(ai.topics.isEmpty) // each group had a skill
    }

    @Test func aGroupWithoutASkillAsksForATopic() async throws {
        let plans = FakePlansRepository(), ai = FakeAIRepository()
        let maker = PlanTest.maker(plans: plans, ai: ai)
        let nikhil = try #require(PlanTest.members.first { $0.id == FakeStudentsRepository.nikhil }) // no book yet
        await maker.make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        #expect(ai.topics.count == 1)
        let plan = try await plan(plans)
        let skill = plan.groups[0].skill
        #expect(!skill.isEmpty && ai.topics.first?.first?.classLevel == .eight)
        #expect(plan.items(of: nikhil.id).first { $0.kind == .teach }?.words == "Teach: \(skill)")
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
    }

    @Test func aFailedFigureLeavesTheRestOfThePlan() async throws {
        let plans = FakePlansRepository(), ai = FakeAIRepository()
        ai
            .scriptByKind[.figure] =
            .failure(.refused("Couldn't draw a figure for this skill. The plan goes on without it."))
        let maker = PlanTest.maker(plans: plans, ai: ai, textbooks: PlanTest.textbooksWithRiyasFractions())
        let riya = try #require(PlanTest.members.first { $0.id == FakeStudentsRepository.riya })
        await maker.make(PlanTest.batch([riya]), choices: nil) { _ in }
        let plan = try await plan(plans)
        #expect(ai.figures == [.fractionBar])
        #expect(plan.artefact(group: 1, kind: .figure) == nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
        #expect(plan.artefact(group: 1, kind: .workedExample) != nil)
    }

    @Test func aSpecTheApiLetThroughButTheAppRefusesIsNotKept() async throws {
        let plans = FakePlansRepository(), ai = FakeAIRepository()
        ai.figureOverride = FigureContent(figure: .foodChain(links: ["Grass"]), caption: "x")
        let maker = PlanTest.maker(plans: plans, ai: ai, textbooks: PlanTest.textbooksWithRiyasFractions())
        let riya = try #require(PlanTest.members.first { $0.id == FakeStudentsRepository.riya })
        await maker.make(PlanTest.batch([riya]), choices: nil) { _ in }
        #expect(ai.figures.count == 1)
        #expect(try await plan(plans).artefact(group: 1, kind: .figure) == nil)
    }

    @Test func personalChecksAreKeptWithTheStudentAndThePlacementAsItsKind() async throws {
        let plans = FakePlansRepository()
        let maker = PlanTest.maker(plans: plans)
        await maker.make(PlanTest.batch(PlanTest.members), choices: nil) { _ in }
        let plan = try await plan(plans)
        let riyas = try #require(plan.checks(for: FakeStudentsRepository.riya))
        #expect(riyas.kind == .placement)
        #expect(riyas.studentID == FakeStudentsRepository.riya)
        #expect(plan.checks(for: FakeStudentsRepository.meher)?.studentID == nil)
    }

    @Test func theChoicesOverrideTheRulesAndThePatternOverridesNothingChosen() async throws {
        let maker = PlanTest.maker(plans: FakePlansRepository())
        let two = try await maker.draft(
            PlanTest.batch(PlanTest.members), choices: PlanChoices(groups: 2, subjects: [1: "Mathematics"])
        )
        #expect(two.groups.count == 2)
        #expect(two.groups[0].subject == "Mathematics")
        var patterned = PlanTest.evening
        patterned.planPattern = [.wednesday: PlanPattern(groups: 1, subjects: ["Science"])]
        let kept = try await maker.draft(
            PlanBatch(
                classroom: patterned,
                members: PlanTest.members,
                date: PlanTest.wednesday,
                centre: PlanTest.centre
            ),
            choices: nil
        )
        #expect(kept.groups.count == 1)
    }

    @Test func nothingPersonalIsSentToTheApi() async {
        let ai = FakeAIRepository()
        let maker = PlanTest.maker(plans: FakePlansRepository(), ai: ai)
        await maker.make(PlanTest.batch(PlanTest.members), choices: nil) { _ in }
        let names = PlanTest.members.flatMap { $0.name.lowercased().split(separator: " ").map(String.init) }
        let sent = (ai.sheets.flatMap(\.self) + ai.examples + ai.briefs + ai.checkCalls.flatMap(\.self)).map {
            $0.lowercased()
        }
        #expect(!sent.isEmpty)
        #expect(sent.allSatisfy { text in !names.contains { text.contains($0) } })
    }

    @Test func aReadThatFailsWritesNoPlan() async {
        let plans = FakePlansRepository()
        let textbooks = FakeTextbooksRepository.evening()
        textbooks.nextError = URLError(.notConnectedToInternet)
        let seen = Seen()
        await PlanTest.maker(plans: plans, textbooks: textbooks)
            .make(PlanTest.batch(PlanTest.members), choices: nil) { progress in await seen.add(progress.name) }
        #expect(plans.made.isEmpty)
        #expect(seen.names == ["failed"])
    }
}

/// The progress names a make reported, in order.
@MainActor final class Seen {
    var names: [String] = []

    func add(_ name: String) {
        names.append(name)
    }
}
