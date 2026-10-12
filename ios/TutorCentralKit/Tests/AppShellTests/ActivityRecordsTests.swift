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
        await recorder.appOpened()
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
