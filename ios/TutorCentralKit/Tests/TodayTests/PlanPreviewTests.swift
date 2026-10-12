import Data
import Domain
import Foundation
import Testing
@testable import Today

/// What the phone still reads around the server's plan: the rules' groups for the Change sheet (exam mode, holidays,
/// the choices), whether the whole batch is on holiday, and each member's book kept for the close offline.
@MainActor struct PlanPreviewTests {
    /// Science unit test 3 for class 8 at Vidya Niketan on Friday 16 (Dev, Meher, Nikhil), shared on Wednesday 7.
    var exam16: SchoolItem {
        FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }!
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

    @Test func anExamInTheWindowTurnsItsStudentsLinesToRevisionAndOneOutsideChangesNothing() async throws {
        let preview = PlanTest.preview(plans: FakePlansRepository(), items: [exam16])
        let draft = try await preview.draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(draft.groups[0].examItemID == exam16.id)
        #expect(teach(draft, FakeStudentsRepository.dev)?.hasPrefix("Revise: ") == true)
        var later = exam16
        later.date = FakeSchoolItemsRepository.day(27)
        let outside = try await PlanTest.preview(plans: FakePlansRepository(), items: [later])
            .draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(outside.groups.allSatisfy { $0.examItemID == nil })
    }

    /// Review Important 1: on the test day the students go back to their level group.
    @Test func theExamDayHasNoExamGroup() async throws {
        let friday16 = FakeSchoolItemsRepository.day(16)
        let preview = PlanTest.preview(plans: FakePlansRepository(), now: PlanTest.at(16, 16, 35), items: [exam16])
        let draft = try await preview.draft(PlanTest.batch(PlanTest.members, on: friday16), choices: nil)
        #expect(draft.groups.allSatisfy { $0.examItemID == nil })
    }

    @Test func aUsedGapReportGivesTheDayAfterTheMockItsLines() async throws {
        let plans = FakePlansRepository(artefacts: [devGapReportUsed])
        let preview = PlanTest.preview(plans: plans, now: PlanTest.at(15, 16, 35), items: [exam16])
        let draft = try await preview.draft(
            PlanTest.batch(PlanTest.members, on: FakeSchoolItemsRepository.day(15)), choices: nil
        )
        #expect(teach(draft, FakeStudentsRepository.dev) == "Balancing equations: the worked example, then a set of 6")
        #expect(teach(draft, FakeStudentsRepository.meher) == "Revise: what the mock showed")
    }

    @Test func aStudentOnHolidayIsLeftOutAndAWholeBatchOnHolidayHasNoPlan() async throws {
        let vidya = FakeSchoolsRepository.vidya.id
        let classEight = holiday(for: .schoolClass(school: vidya, level: .eight))
        let preview = PlanTest.preview(plans: FakePlansRepository(), items: [classEight])
        let draft = try await preview.draft(PlanTest.batch(PlanTest.members), choices: nil)
        #expect(Set(draft.leftOut) == [
            FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil,
        ])
        #expect(await !preview.wholeBatchOnHoliday(PlanTest.batch(PlanTest.members)))
        let all = PlanTest.preview(plans: FakePlansRepository(), items: [
            holiday(for: .school(vidya)), holiday(for: .student(FakeStudentsRepository.sahil)),
        ])
        #expect(await all.wholeBatchOnHoliday(PlanTest.batch(PlanTest.members)))
    }

    @Test func theChoicesOverrideTheRulesAndThePatternOverridesNothingChosen() async throws {
        let preview = PlanTest.preview(plans: FakePlansRepository())
        let two = try await preview.draft(
            PlanTest.batch(PlanTest.members), choices: PlanChoices(groups: 2, subjects: [1: "Mathematics"])
        )
        #expect(two.groups.count == 2 && two.groups[0].subject == "Mathematics")
        var patterned = PlanTest.evening
        patterned.planPattern = [.wednesday: PlanPattern(groups: 1, subjects: ["Science"])]
        let kept = try await preview.draft(PlanTest.batch(PlanTest.members, classroom: patterned), choices: nil)
        #expect(kept.groups.count == 1)
    }

    @Test func eachMembersBookIsKeptOnThisIPhone() async throws {
        let cache = PlanCache(
            centre: PlanTest.centre,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        await PlanTest.preview(plans: FakePlansRepository(), cache: cache).keepBooks(of: PlanTest.members)
        let dev = try #require(cache.book(student: FakeStudentsRepository.dev))
        #expect(dev.skills.map(\.id) == FakeTextbooksRepository.evening().skillsByStudent[FakeStudentsRepository.dev]?
            .sorted { $0.position < $1.position }.map(\.id))
    }
}
