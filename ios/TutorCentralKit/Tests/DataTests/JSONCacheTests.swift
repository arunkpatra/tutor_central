import Foundation
import Testing
@testable import Data

struct JSONCacheTests {
    struct Note: Codable, Equatable {
        let text: String
        let at: Date
    }

    @Test func savesLoadsAndRemoves() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = JSONCache<[Note]>(name: "notes", directory: dir)
        #expect(cache.load() == nil)
        let notes = [Note(text: "a", at: Date(timeIntervalSince1970: 1_000_000))]
        try cache.save(notes)
        #expect(cache.load() == notes && cache.url.lastPathComponent == "notes.json")
        cache.remove()
        #expect(cache.load() == nil)
    }

    @Test func aCorruptFileReadsAsNothing() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = JSONCache<[Note]>(name: "bad", directory: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: cache.url)
        #expect(cache.load() == nil)
    }
}
