import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakePlansRepositoryTests {
    @Test func makeThenKeepLinksTheGroupsItems() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        #expect(made.items.count == PlanSamples.sampleDraft.lines.count)
        let sheet = try await repo.keep(
            NewArtefact(kind: .sheet, source: .made, title: "s", content: .sheet(SheetContent(
                title: "s",
                instructions: nil,
                questions: [],
                forHomework: true,
                light: false
            )), photoPath: nil, generationID: nil, regeneratedFrom: nil),
            to: ArtefactLink(plan: made.id, group: 1, student: nil, itemKind: .homework), centre: centre
        )
        let read = try try await #require(repo.plan(centre: centre, classID: made.classID, date: made.date))
        #expect(read.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy { $0.artefactID == sheet.id })
        #expect(read.artefacts.map(\.id) == [sheet.id])
    }

    @Test func aSecondMakeReplacesTheDaysPlanAndUnlinksItsArtefacts() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let first = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        let second = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        #expect(first.id == second.id)
        #expect(try await repo.plan(centre: centre, classID: second.classID, date: second.date)?.artefacts
            .isEmpty == true)
    }

    @Test func skipMoveAndLeaveOutMarkTheItems() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        let dev = try #require(made.items[0].studentID)
        try await repo.skip(item: #require(made.items(of: dev).first { $0.kind == .homework }?.id), centre: centre)
        try await repo.move(items: made.items(of: dev).map(\.id), to: 2, from: 1, centre: centre)
        var read = try try await #require(repo.plan(centre: centre, classID: made.classID, date: made.date))
        #expect(read.items(of: dev).allSatisfy { $0.groupNo == 2 && $0.movedFrom == 1 })
        #expect(read.items(of: dev).first { $0.kind == .homework }?.skippedAt != nil)
        try await repo.leaveOut(student: dev, plan: made.id, centre: centre)
        read = try try await #require(repo.plan(centre: centre, classID: made.classID, date: made.date))
        #expect(read.items(of: dev).allSatisfy { $0.skippedAt != nil })
    }

    @Test func briefChaptersNameTheChaptersBriefsWereMadeFor() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanSamples.sampleDraft, centre: centre)
        _ = try await repo.keep(
            NewArtefact(
                kind: .brief,
                source: .made,
                title: "Your brief · Chemical reactions",
                content: .other,
                photoPath: nil,
                generationID: nil,
                regeneratedFrom: nil
            ),
            to: ArtefactLink(plan: made.id, group: 1, student: nil, itemKind: .brief), centre: centre
        )
        #expect(try await repo.briefChapters(centre: centre) == ["Chemical reactions"])
    }
}
