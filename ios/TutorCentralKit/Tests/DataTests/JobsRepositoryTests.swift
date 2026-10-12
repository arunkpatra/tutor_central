import Domain
import Foundation
import Supabase
import Testing
@testable import Data

@MainActor struct JobsRepositoryTests {
    let centre = UUID(), classID = UUID()
    let day = Day(year: 2026, month: 10, day: 7)!

    @Test func aPlanRequestNamesTheDayAndAnyChoicesAsTheJobReadsThem() {
        let plain = SupabaseJobsRepository.planParams(centre: centre, classID: classID, date: day, choices: nil)
        #expect(plain["p_date"] == .string("2026-10-07") && plain["p_choices"] == .null)
        let chosen = SupabaseJobsRepository.planParams(
            centre: centre, classID: classID, date: day, choices: PlanChoices(groups: 2, subjects: [1: "Science"])
        )
        #expect(chosen["p_choices"] == .object(["groups": .integer(2), "subjects": .object(["1": .string("Science")])]))
        // Choices with nothing chosen still replace the day's plan: an empty object, never null.
        let again = SupabaseJobsRepository.planParams(
            centre: centre, classID: classID, date: day, choices: PlanChoices(groups: nil, subjects: [:])
        )
        #expect(again["p_choices"] == .object(["subjects": .object([:])]))
    }

    @Test func aJobRowReadsItsStateAndItsReason() throws {
        let json = """
        [{"id":"\(UUID().uuidString)","state":"done","created_at":"2026-10-07T00:30:00.123+00:00",
          "finished_at":"2026-10-07T00:31:00+00:00","result":{"plan_id":null,"reason":"holiday"}}]
        """
        let rows = try PostgRESTDecoder.make().decode([SupabaseJobsRepository.Row].self, from: Data(json.utf8))
        let status = try #require(rows.first?.status)
        #expect(status.state == .done && status.reason == "holiday" && !status.isLive && status.finishedAt != nil)
    }

    @Test func theFakeAnswersTheLiveJobAndRecordsCancels() async throws {
        let jobs = FakeJobsRepository()
        let first = try await jobs.requestPlan(centre: centre, classID: classID, date: day, choices: nil)
        let second = try await jobs.requestPlan(centre: centre, classID: classID, date: day, choices: nil)
        #expect(first == second && jobs.requested.count == 2)
        try await jobs.cancel(centre: centre, job: first)
        #expect(jobs.cancelled == [first])
        #expect(try await jobs.planJob(centre: centre, classID: classID, date: day)?.state == .cancelled)
    }
}
