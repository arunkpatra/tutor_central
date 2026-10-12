import Domain
import Foundation
import Testing
@testable import Data

/// The app's activity (D77, D82): gathered in a file, posted in batches of twenty, kept on a failure, at most 500.
struct ActivityLogTests {
    let centre = UUID()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("activity-\(UUID().uuidString)")

    func log(_ repository: FakeActivityRepository, batch: Int = 20, cap: Int = 500) -> ActivityLog {
        ActivityLog(centre: centre, repository: repository, directory: directory, batch: batch, cap: cap)
    }

    @Test func theTwentiethEventPostsTheBatchInOrder() async {
        let repository = FakeActivityRepository()
        let log = log(repository)
        for index in 1 ... 19 {
            await log.record(.tabOpened, screen: "tab\(index)")
        }
        #expect(repository.batches.isEmpty)
        await log.record(.appOpened)
        let posted = repository.batches
        #expect(posted.count == 1 && posted[0].count == 20)
        #expect(posted[0].first?.screen == "tab1" && posted[0].last?.kind == .appOpened)
        #expect(await log.pending == 0)
    }

    @Test func aFailedPostKeepsTheEventsForTheNextFlush() async {
        let repository = FakeActivityRepository(failures: 1)
        let log = log(repository, batch: 3)
        for _ in 1 ... 3 {
            await log.record(.tabOpened, screen: "today")
        }
        #expect(await log.pending == 3 && repository.batches.isEmpty)
        await log.flush()
        #expect(await log.pending == 0 && repository.batches.first?.count == 3)
    }

    @Test func theFileHoldsAtMostTheCapTheOldestGoing() async {
        let repository = FakeActivityRepository(failures: 100)
        let log = log(repository, batch: 1000, cap: 5)
        for index in 1 ... 7 {
            await log.record(.tabOpened, screen: "s\(index)")
        }
        #expect(await log.pending == 5)
        let again = ActivityLog(centre: centre, repository: FakeActivityRepository(), directory: directory)
        await again.flush()
    }

    @Test func eventsSurviveANewLogOnTheSameFile() async {
        let failing = FakeActivityRepository(failures: 100)
        let first = log(failing)
        await first.record(.signedIn)
        await first.record(.tabOpened, screen: "students")
        let repository = FakeActivityRepository()
        let second = log(repository)
        #expect(await second.pending == 2)
        await second.flush()
        #expect(repository.batches.first?.map(\.kind) == [.signedIn, .tabOpened])
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent(
            "activity-\(centre.uuidString.lowercased()).json"
        ).path))
    }

    @Test func flushWithNothingPostsNothing() async {
        let repository = FakeActivityRepository()
        await log(repository).flush()
        #expect(repository.batches.isEmpty)
    }
}
