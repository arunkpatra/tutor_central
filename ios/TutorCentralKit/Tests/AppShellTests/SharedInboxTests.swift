import Foundation
import Testing
@testable import AppShell

struct SharedInboxTests {
    @Test func readsItemsInOrderAndLeavesThem() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: dir.appendingPathComponent("inbox"),
            withIntermediateDirectories: true
        )
        let first = #"{"kind":"text","text":"FA2 on Monday","receivedAt":"2026-10-12T10:00:00Z"}"#
        let second = #"{"kind":"image","file":"x.jpg","receivedAt":"2026-10-12T11:00:00Z"}"#
        try second.write(to: dir.appendingPathComponent("inbox/b.json"), atomically: true, encoding: .utf8)
        try first.write(to: dir.appendingPathComponent("inbox/a.json"), atomically: true, encoding: .utf8)
        try Data([0xFF, 0xD8]).write(to: dir.appendingPathComponent("inbox/x.jpg"))
        let items = try SharedInbox(container: dir).items()
        #expect(items.map(\.kind) == [.text, .image] && items[0].text == "FA2 on Monday" && items[1].file == "x.jpg")
        #expect(try SharedInbox(container: dir).items().count == 2)
    }

    @Test func anEmptyOrMissingInboxIsEmpty() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(try SharedInbox(container: dir).items().isEmpty)
    }

    /// The extension writes its item with JSONEncoder (Share/ShareViewController.swift): a text with quotes, a new line
    /// and a backslash reads back whole; a file that is not an item is passed over.
    @Test func whatTheExtensionWritesIsWhatTheAppReads() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let inbox = dir.appendingPathComponent("inbox")
        try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
        let text = "Science test \"Monday\"\nCh 1–3 \\ revise"
        let item: [String: String] = ["kind": "text", "text": text, "receivedAt": "2026-10-12T10:00:00Z"]
        try JSONSerialization.data(withJSONObject: item).write(to: inbox.appendingPathComponent("one.json"))
        try Data("not json".utf8).write(to: inbox.appendingPathComponent("broken.json"))
        let items = try SharedInbox(container: dir).items()
        #expect(items.count == 1 && items[0].text == text)
    }
}
