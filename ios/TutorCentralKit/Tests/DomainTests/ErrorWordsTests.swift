import Foundation
import Testing

/// D41: no technical or internal word in anything a tutor reads. Every sentence-like string literal in the app's
/// sources (a capital letter, then words) is read from disk and checked; the fakes and a broken build's `fatalError`
/// never reach a tutor and are skipped.
struct ErrorWordsTests {
    static let banned = [
        "server", "servers", "sync", "syncing", "synced", "cache", "cached", "queue", "queued", "upload", "uploaded",
        "database", "supabase", "postgrest", "api", "http", "json", "token", "backend", "request", "error code",
    ]

    static var sources: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources")
    }

    static func sentences() throws -> [(file: String, text: String)] {
        let files = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" && !$0.lastPathComponent.hasPrefix("Fake") } ?? []
        let literal = /"([A-Z][^"\\]*(?: [^"\\]*)+)"/
        var found: [(String, String)] = []
        for file in files {
            for line in try String(contentsOf: file, encoding: .utf8).split(separator: "\n")
                where !line.contains("fatalError(") && !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for match in line.matches(of: literal) {
                    found.append((file.lastPathComponent, String(match.1)))
                }
            }
        }
        return found
    }

    @Test func theSourcesAreFound() throws {
        #expect(try Self.sentences().count > 200)
    }

    @Test func noSentenceOnScreenUsesATechnicalWord() throws {
        for (file, text) in try Self.sentences() {
            let words = Set(text.lowercased().split { !$0.isLetter && $0 != " " }.flatMap { $0.split(separator: " ") }
                .map(String.init))
            for word in Self.banned {
                let hit = word.contains(" ") ? text.lowercased().contains(word) : words.contains(word)
                #expect(!hit, "\(file): \"\(text)\" says \"\(word)\"")
            }
        }
    }
}
