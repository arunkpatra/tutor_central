import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Today

/// The plan made by the server (plan/phase-18-plan.md decision 18): the store reads the plan and the day's job, asks
/// for one when there is neither, follows a live job, and never calls the AI.
@MainActor struct PlanStoreJobTests {
    let base = PlanStoreTests()
    let evening = PlanTest.evening.id

    @Test func noPlanAndAFailedJobShowsTheFailedCardAndTryAgainAsksTheServer() async {
        let jobs = FakeJobsRepository(planJobs: [
            evening: JobStatus(id: UUID(), state: .failed, createdAt: PlanTest.at(7, 5, 30)),
        ])
        let store = await base.store(jobs: jobs)
        #expect(store.state == .failed("Couldn't make today's plan. Try again in a minute."))
        #expect(jobs.requested.isEmpty)
        await store.tryAgain()
        #expect(jobs.requested == [.plan(classID: evening, date: PlanTest.wednesday, choices: nil)])
        #expect(store.state == .planning(nil))
    }

    @Test func noPlanAndNoJobAsksForOneAndShowsPlanning() async {
        let jobs = FakeJobsRepository()
        let store = await base.store(jobs: jobs)
        #expect(store.state == .planning(nil))
        #expect(jobs.requested == [.plan(classID: evening, date: PlanTest.wednesday, choices: nil)])
    }

    @Test func aJobDoneForAHolidayShowsNoPlanAndAsksNothing() async {
        let jobs = FakeJobsRepository(planJobs: [
            evening: JobStatus(id: UUID(), state: .done, createdAt: PlanTest.at(7, 5, 30), reason: "holiday"),
        ])
        let store = await base.store(jobs: jobs)
        #expect(store.state == .holiday && jobs.requested.isEmpty)
    }

    @Test func cancelOnThePlanningCardCancelsTheJob() async throws {
        let jobs = FakeJobsRepository()
        let store = await base.store(jobs: jobs)
        let job = try #require(jobs.planJobs[evening]?.id)
        await store.cancel()
        #expect(jobs.cancelled == [job])
        #expect(store.state == .none)
    }

    @Test func makeThePlanAgainSendsTheChoicesAndWaits() async {
        let plans = FakePlansRepository.evening()
        let jobs = FakeJobsRepository()
        let store = await base.store(plans: plans, jobs: jobs)
        guard case .made = store.state else { Issue.record("not made: \(store.state)")
            return
        }
        let two = PlanChoices(groups: 2, subjects: [1: "Mathematics"])
        await store.useToday(choices: two)
        #expect(jobs.requested == [.plan(classID: evening, date: PlanTest.wednesday, choices: two)])
        // The plan still there is being replaced: the planning card, not the old plan.
        #expect(store.state == .planning(nil))
    }

    @Test func aSchoolItemChangeAsksForAReplacingPlanForADayNotClosed() async {
        let jobs = FakeJobsRepository()
        let store = await base.store(plans: FakePlansRepository.evening(), jobs: jobs)
        await store.remake(for: [FakeStudentsRepository.dev])
        #expect(jobs.requested == [
            .plan(classID: evening, date: PlanTest.wednesday, choices: PlanChoices(groups: nil, subjects: [:])),
        ])
    }

    @Test func whileTheJobIsLiveTheStoreReadsAgainUntilItIsDone() async throws {
        let plans = FakePlansRepository.eveningMaking()
        let jobs = FakeJobsRepository(planJobs: [
            evening: JobStatus(id: UUID(), state: .running, createdAt: PlanTest.at(7, 5, 30)),
        ])
        let store = await base.store(
            plans: plans, jobs: jobs, now: PlanTest.at(7, 6, 5), pause: { try await Task.sleep(for: .milliseconds(5)) }
        )
        let until = ContinuousClock.now.advanced(by: .seconds(5))
        while jobs.reads < 3, ContinuousClock.now < until {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(jobs.reads >= 3)
        guard case .planning = store.state else { Issue.record("not following: \(store.state)")
            return
        }
        jobs.planJobs[evening] = JobStatus(id: UUID(), state: .done, createdAt: PlanTest.at(7, 5, 30))
        while store.planning, ContinuousClock.now < until {
            try await Task.sleep(for: .milliseconds(10))
        }
        guard case .made = store.state else { Issue.record("not made when the job was done: \(store.state)")
            return
        }
        #expect(store.madeLine == nil && store.groups[0].marks.map(\.state) == [.made, .made, .notMade, .notMade])
        let reads = jobs.reads
        try await Task.sleep(for: .milliseconds(50))
        #expect(jobs.reads == reads)
    }

    @Test func behindTheAppTheReadsStop() async throws {
        let jobs = FakeJobsRepository(planJobs: [
            evening: JobStatus(id: UUID(), state: .running, createdAt: PlanTest.at(7, 5, 30)),
        ])
        let store = await base.store(
            plans: FakePlansRepository.eveningMaking(), jobs: jobs, now: PlanTest.at(7, 6, 5), load: false,
            pause: { try await Task.sleep(for: .milliseconds(5)) }
        )
        store.inFront = { false }
        await store.load()
        try await Task.sleep(for: .milliseconds(60))
        #expect(jobs.reads == 1)
    }

    @Test func aFailedReadKeepsTheCopy() async {
        let cache = PlanCache(
            centre: PlanTest.centre,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        _ = await base.store(plans: FakePlansRepository.evening(), cache: cache)
        let plans = FakePlansRepository()
        plans.nextError = URLError(.timedOut)
        let store = await base.store(plans: plans, jobs: FakeJobsRepository(), cache: cache)
        guard case let .made(plan) = store.state else { Issue.record("the copy went: \(store.state)")
            return
        }
        #expect(plan.id == FakePlansRepository.planID)
    }

    /// Decision 14: the plan and its material are the server's; the store has no way to the AI.
    @Test func theStoreNeverCallsTheAI() async {
        let store = await base.store(load: false)
        let parts = Mirror(reflecting: store).children.map { type(of: $0.value) }
        #expect(!parts.contains { "\($0)".contains("AIRepository") })
    }
}
