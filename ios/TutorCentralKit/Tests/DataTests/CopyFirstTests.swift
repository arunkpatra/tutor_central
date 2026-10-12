import Foundation
import Testing
@testable import Data

@MainActor struct CopyFirstTests {
    final class Shown {
        var values: [(String, Date)] = []
    }

    let saved = Date(timeIntervalSince1970: 1000)
    let now = Date(timeIntervalSince1970: 2000)

    func cache(_ value: String?) -> CachedRead<String> {
        let read = CachedRead<String>(
            centre: UUID(), key: "t",
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        if let value {
            read.keep(value, at: saved)
        }
        return read
    }

    @Test func theCopyIsShownBeforeTheReadReturnsThenTheReadReplacesAndIsKept() async {
        let cache = cache("copy")
        let shown = Shown()
        let (stream, gate) = AsyncStream<Void>.makeStream()
        let now = now
        let run = Task {
            await CopyFirst(cache: cache, now: { now }).load(show: { shown.values.append(($0, $1)) }, read: {
                for await _ in stream {
                    break
                }
                return "fresh"
            })
        }
        while shown.values.isEmpty {
            await Task.yield()
        }
        #expect(shown.values.map(\.0) == ["copy"] && shown.values.first?.1 == saved)
        gate.yield()
        guard case .fresh = await run.value else { Issue.record("not fresh")
            return
        }
        #expect(shown.values.map(\.0) == ["copy", "fresh"] && shown.values.last?.1 == now)
        #expect(cache.load()?.value == "fresh" && cache.load()?.savedAt == now)
    }

    @Test func aFailedReadKeepsTheCopy() async {
        let cache = cache("copy")
        let shown = Shown()
        let outcome = await CopyFirst(cache: cache, now: { [now] in now })
            .load(show: { shown.values.append(($0, $1)) }, read: { throw URLError(.notConnectedToInternet) })
        guard case .keptCopy = outcome else { Issue.record("not kept: \(outcome)")
            return
        }
        #expect(shown.values.map(\.0) == ["copy"] && cache.load()?.value == "copy")
    }

    @Test func nothingSavedAndAFailureIsNothing() async {
        let shown = Shown()
        let outcome = await CopyFirst(cache: cache(nil), now: { [now] in now })
            .load(show: { shown.values.append(($0, $1)) }, read: { throw URLError(.timedOut) })
        guard case .nothing = outcome else { Issue.record("not nothing: \(outcome)")
            return
        }
        #expect(shown.values.isEmpty && outcome.failure != nil)
    }

    @Test func aListAlreadyNewerSkipsTheCopy() async {
        let shown = Shown()
        _ = await CopyFirst(cache: cache("copy"), now: { [now] in now })
            .load(showingCopy: false, show: { shown.values.append(($0, $1)) }, read: { "fresh" })
        #expect(shown.values.map(\.0) == ["fresh"])
    }
}
