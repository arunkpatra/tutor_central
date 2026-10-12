import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

extension NoteStoreTests {
    /// The note day's job done in place: an asked note written from the week and kept (the writer the phone's taps
    /// use).
    static func serving(_ world: World, reader: NoteRecordReader) -> FakeJobsRepository {
        let jobs = FakeJobsRepository()
        let writer = NoteWriter(
            workspace: FakeCentreRepository.meeraWorkspace, plans: world.plans, ai: world.ai, calendar: DayHeading.india
        )
        jobs.onNoteRequest = { id, _ in
            let week = NoteDay.week(ending: noteDay, calendar: DayHeading.india)
            guard let student = students().first(where: { $0.id == id }),
                  let record = try? await reader.read(
                      [student], centre: FakeCentreRepository.meeraWorkspace.centre.id, from: week.lowerBound,
                      to: noteDay, calendar: DayHeading.india
                  )[id] else { return }
            _ = try? await writer.write(student, record: record, week: week, saying: nil, replacing: nil)
        }
        return jobs
    }
}

/// The note from the note day's job (Phase 18, plan Task 19): a kept note opens with no call; a missing one is asked of
/// the server and waited for; Write again is still a call of the phone's, with a fresh key.
@MainActor struct NoteStoreJobTests {
    typealias Base = NoteStoreTests

    @Test func aKeptNoteOpensWithNoCall() async {
        var world = Base.World()
        world.jobs = FakeJobsRepository()
        let first = await Base.make(Base.dev, Base.World(plans: world.plans))
        await first.load()
        let calls = world.ai.noteCalls.count
        let store = await Base.make(Base.dev, world)
        await store.load()
        #expect(store.stage == .ready && world.ai.noteCalls.count == calls && world.jobs?.requested.isEmpty == true)
    }

    @Test func aMissingNoteIsAskedOfTheServerAndShowsWriting() async throws {
        var world = Base.World()
        let jobs = FakeJobsRepository()
        world.jobs = jobs
        let store = await Base.make(Base.dev, world)
        let load = Task { await store.load() }
        await load.value
        #expect(try jobs.requested == [.note(student: Base.dev, week: #require(Day(year: 2026, month: 10, day: 5)))])
        #expect(world.ai.noteCalls.isEmpty)
        // Two minutes without the note: the timed-out words, Try Again offered.
        #expect(store.stage == .failed("That took too long to come back. Try again in a minute.") && store.canRetry)
        #expect(!store.facts.isEmpty)
    }

    @Test func theAskedNoteAppearsWhenTheJobKeepsIt() async {
        let world = Base.World()
        let store = await Base.make(Base.dev, world)
        await store.load()
        #expect(store.stage == .ready && !store.message.isEmpty)
        #expect(world.ai.noteCalls.count == 1)
    }

    @Test func aStudentWithoutConsentIsNotAsked() async {
        var world = Base.World()
        let jobs = FakeJobsRepository()
        world.jobs = jobs
        let store = await Base.make(Base.riya, world)
        await store.load()
        #expect(jobs.requested.isEmpty)
        guard case .failed = store.stage else { Issue.record("not held: \(store.stage)")
            return
        }
    }

    @Test func writeAgainStillCallsWithAFreshKey() async {
        var world = Base.World()
        world.jobs = FakeJobsRepository()
        let first = await Base.make(Base.dev, Base.World(ai: world.ai, plans: world.plans))
        await first.load()
        let store = await Base.make(Base.dev, world)
        await store.load()
        let calls = world.ai.noteCalls.count
        await store.writeAgain()
        #expect(world.ai.noteCalls.count == calls + 1 && world.ai.anotherCalls == 1)
        #expect(world.jobs?.requested.isEmpty == true)
    }
}
