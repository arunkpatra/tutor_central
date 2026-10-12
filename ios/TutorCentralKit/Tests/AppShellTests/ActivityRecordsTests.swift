import Data
import Domain
import Foundation
import Testing
@testable import AppShell

/// What the shell records, and when (D82; plan decision 16): the app opened, a sign-in, a tab, a link, a sign-out
/// (posted
/// before the wipe).
@MainActor struct ActivityRecordsTests {
    let centre = UUID()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("records-\(UUID().uuidString)")

    func recorder(_ repository: FakeActivityRepository) -> ActivityRecorder {
        ActivityRecorder(log: ActivityLog(centre: centre, repository: repository, directory: directory))
    }

    @Test func theAppOpenedASignInATabAndALinkAreRecorded() async {
        let repository = FakeActivityRepository()
        let recorder = recorder(repository)
        await recorder.cameBack()
        await recorder.signedIn()
        await recorder.tabChosen(.students)
        await recorder.linkOpened(.student(UUID()))
        await recorder.flush()
        let events = repository.batches.flatMap(\.self)
        #expect(events.map(\.kind) == [.appOpened, .signedIn, .tabOpened, .linkOpened])
        #expect(events.map(\.screen) == [nil, nil, "students", "student"])
    }

    @Test func signOutRecordsItselfAndPostsBeforeTheWipe() async {
        let repository = FakeActivityRepository()
        let recorder = recorder(repository)
        await recorder.tabChosen(.fees)
        await recorder.signingOut()
        #expect(repository.batches.flatMap(\.self).map(\.kind) == [.tabOpened, .signedOut])
    }

    @Test func aLinkIsNamedByItsKindNeverItsId() {
        #expect(ActivityRecorder.screen(of: .fees(month: "2026-10")) == "fees")
        #expect(ActivityRecorder.screen(of: .attendance(date: nil, classID: nil)) == "attendance")
        #expect(ActivityRecorder.screen(of: .school(UUID())) == "school")
        #expect(ActivityRecorder.screen(of: .event(UUID())) == "event")
        #expect(ActivityRecorder.screen(of: .today) == "today")
    }
}

/// The review's findings 4 and 5: the app opened is recorded at a cold launch, once the centre's log is made, and on
/// each
/// return, in a task of its own (the return's refresh never waits for the post).
@MainActor struct ActivityOpenedTests {
    let files = FileManager.default.temporaryDirectory.appendingPathComponent("opened-\(UUID().uuidString)")

    @Test func aLaunchBeforeTheCentreIsReadIsRecordedWhenTheLogIsMadeAndEachReturnAfter() async {
        let shell = ShellState(), repository = FakeActivityRepository()
        shell.opened()
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace), files: files, activity: repository)
        await Self.until { repository.batches.count == 1 }
        shell.sessionChanged(.ready(Fixtures.meeraWorkspace), files: files, activity: repository)
        shell.opened()
        await Self.until { repository.batches.count == 2 }
        #expect(repository.batches.flatMap(\.self).map(\.kind) == [.appOpened, .appOpened])
    }

    static func until(_ done: () -> Bool) async {
        for _ in 0 ..< 1000 where !done() {
            await Task.yield()
        }
    }
}
