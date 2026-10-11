import Foundation
import School
import Testing
@testable import AppShell

/// The share hand-off (plan/phase-13-plan.md decision 25): an inbox item opens "Check what was read" on the School tab
/// once signed in, one at a time.
@MainActor struct InboxHandoffTests {
    func inbox(_ texts: [String]) throws -> SharedInbox {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let folder = dir.appendingPathComponent("inbox")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (index, text) in texts.enumerated() {
            let item: [String: String] = ["kind": "text", "text": text, "receivedAt": "2026-10-12T1\(index):00:00Z"]
            try JSONSerialization.data(withJSONObject: item)
                .write(to: folder.appendingPathComponent("item\(index).json"))
        }
        return SharedInbox(container: dir)
    }

    func readRoute(_ shell: ShellState) -> Route? {
        shell.tabs.paths[.school]?.first {
            if case .schoolRead = $0 {
                true
            } else {
                false
            }
        }
    }

    @Test func anInboxItemWaitsForSignIn() throws {
        let shared = try inbox(["Unit test on Friday"])
        let shell = ShellState()
        shell.inboxHandoff(shared, signedIn: false)
        #expect(shell.tabs.paths.values.allSatisfy(\.isEmpty) && shell.tabs.selected == .today)
        shell.inboxHandoff(shared, signedIn: true)
        #expect(shell.tabs.selected == .school)
        guard case let .schoolRead(.shared(read))? = readRoute(shell) else {
            Issue.record("no read screen")
            return
        }
        #expect(read.text == "Unit test on Friday" && read.id == "item0")
    }

    @Test func twoItemsAreReadOneAfterTheOther() throws {
        let shared = try inbox(["First", "Second"])
        let shell = ShellState()
        shell.inboxHandoff(shared, signedIn: true)
        let first = try #require(readRoute(shell))
        shell.inboxHandoff(shared, signedIn: true)
        #expect(shell.tabs.paths[.school]?.count == 1)
        // The first is added or left: its file goes and its screen leaves.
        try shared.remove(id: "item0")
        shell.tabs.remove(first)
        shell.inboxHandoff(shared, signedIn: true)
        guard case let .schoolRead(.shared(read))? = readRoute(shell) else {
            Issue.record("no second read screen")
            return
        }
        #expect(read.text == "Second")
    }

    @Test func aHandoffDoesNotStackASecondReadScreen() throws {
        let shared = try inbox(["One"])
        let shell = ShellState()
        shell.tabs.selected = .school
        shell.tabs.push(.schoolRead(.typed))
        shell.inboxHandoff(shared, signedIn: true)
        #expect(shell.tabs.paths[.school] == [.schoolRead(.typed)])
    }
}
