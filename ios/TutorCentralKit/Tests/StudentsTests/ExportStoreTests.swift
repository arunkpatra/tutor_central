import Data
import Domain
import Foundation
import Synchronization
import Testing
@testable import Students

/// A student's export (P18-Export-*; D79): asked once, followed while made, ready with its time and pages, not made
/// with Try Again, older than seven days back to the ask, shared from one download.
@MainActor struct ExportStoreTests {
    nonisolated static let now = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 12,
        hour: 16,
        minute: 5
    ))!
    let hemanth = FakeStudentsRepository.hemanth

    final class Downloads: Sendable {
        let count = Mutex(0)
    }

    func store(
        jobs: FakeJobsRepository, online: Bool = true, downloads: Downloads = Downloads()
    ) async -> ExportStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { Self.now }
        )
        await register.load()
        let files = ServerFiles(
            centre: FakeCentreRepository.meeraWorkspace.centre.id,
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        ) { _, _ in
            downloads.count.withLock { $0 += 1 }
            return Data("%PDF".utf8)
        }
        return ExportStore(
            studentID: hemanth, register: register, jobs: jobs, files: files, now: { Self.now }, online: { online },
            pause: {}
        )
    }

    func at(_ hour: Int, _ minute: Int, day: Int = 12) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func ready(day: Int = 12) -> JobStatus {
        JobStatus(
            id: UUID(), state: .done, createdAt: at(16, 2, day: day), finishedAt: at(16, 3, day: day),
            file: JobFile(path: "c/s/j.pdf", pages: 5, madeAt: at(16, 3, day: day))
        )
    }

    @Test func makeTheFileAsksOnceAndShowsMaking() async {
        let jobs = FakeJobsRepository(now: { Self.now })
        let store = await store(jobs: jobs)
        await store.load()
        #expect(store.state == .ask && store.title == "Everything about Hemanth")
        #expect(store.line == "His details, attendance, fees, record, marks, and the notes and messages made about "
            + "him, in one PDF.")
        await store.make()
        #expect(jobs.requested == [.export(student: hemanth)])
        #expect(store.title == "Making the file")
        #expect(store.line == "Asked at 16:05. Usually ready in a minute; you can leave this page.")
        #expect(store.footnote == "For his parent, when they ask what you keep about him.")
        store.stop()
    }

    @Test func aDoneJobShowsReadyWithTheTimeAndPages() async {
        let jobs = FakeJobsRepository(now: { Self.now })
        jobs.exportJobs[hemanth] = ready()
        let store = await store(jobs: jobs)
        await store.load()
        #expect(store.title == "Ready to share" && store.line == "Made today at 16:03 · PDF, 5 pages")
        #expect(store
            .footnote == "Kept for 7 days, then removed from Tutor Central. Make it again whenever you need it.")
    }

    @Test func aMadeFileArrivesWhileThePageWaits() async throws {
        let jobs = FakeJobsRepository(now: { Self.now })
        jobs.exportJobs[hemanth] = JobStatus(id: UUID(), state: .running, createdAt: at(16, 2))
        let store = await store(jobs: jobs)
        await store.load()
        jobs.exportJobs[hemanth] = ready()
        let until = ContinuousClock.now.advanced(by: .seconds(3))
        while store.title != "Ready to share", ContinuousClock.now < until {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(store.title == "Ready to share")
    }

    @Test func aFailedJobShowsTryAgainAndTryAgainAsksAgain() async {
        let jobs = FakeJobsRepository(now: { Self.now })
        jobs.exportJobs[hemanth] = JobStatus(id: UUID(), state: .failed, createdAt: at(16, 2))
        let store = await store(jobs: jobs)
        await store.load()
        #expect(store.state == .failed && store.line == "Nothing was shared. Try again in a minute.")
        await store.make()
        #expect(jobs.requested == [.export(student: hemanth)])
        store.stop()
    }

    @Test func aFileOlderThanSevenDaysReadsAsTheAsk() async {
        let jobs = FakeJobsRepository(now: { Self.now })
        jobs.exportJobs[hemanth] = ready(day: 4)
        let store = await store(jobs: jobs)
        await store.load()
        #expect(store.state == .ask)
    }

    @Test func offlineMakeTheFileIsRefusedWithTheConsentWords() async {
        let jobs = FakeJobsRepository(now: { Self.now })
        let store = await store(jobs: jobs, online: false)
        await store.make()
        #expect(jobs.requested.isEmpty && store.failure == OfflineRefusal.words(for: .consent) && store.state == .ask)
    }

    @Test func shareDownloadsTheFileOnceAndHandsItOver() async throws {
        let jobs = FakeJobsRepository(now: { Self.now })
        jobs.exportJobs[hemanth] = ready()
        let downloads = Downloads()
        let store = await store(jobs: jobs, downloads: downloads)
        await store.load()
        await store.share()
        let shared = try #require(store.shared)
        #expect(shared.lastPathComponent == "Hemanth Reddy · everything kept.pdf")
        store.shareDone()
        await store.share()
        #expect(store.shared != nil && downloads.count.withLock { $0 } == 1)
    }
}
