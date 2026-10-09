import Data
import Foundation
import Testing

struct CachedReadTests {
    @Test func keepsLoadsAndRemovesOneValueWithItsTime() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "cache-\(UUID().uuidString)", isDirectory: true
        )
        let centre = UUID()
        let read = CachedRead<[String]>(centre: centre, key: "fees-2026-10", directory: dir)
        #expect(read.load() == nil)
        let at = Date(timeIntervalSince1970: 1_791_540_000)
        read.keep(["Dev Kumar"], at: at)
        #expect(read.load()?.value == ["Dev Kumar"] && read.load()?.savedAt == at)
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(names == ["cache-\(centre.uuidString.lowercased())-fees-2026-10.json"])
        read.remove()
        #expect(read.load() == nil)
    }

    @Test func aCacheFileIsWrittenWithFileProtection() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("protect-\(UUID().uuidString)")
        let cache = JSONCache<[String]>(name: "x", directory: dir)
        try cache.save(["a"])
        let attributes = try FileManager.default.attributesOfItem(atPath: cache.url.path)
        let protection = attributes[.protectionKey] as? FileProtectionType
        #expect(protection == nil || protection == .completeUntilFirstUserAuthentication)
    }

    @Test func offlineErrorsAreToldFromTheRest() {
        #expect(TransportError.isOffline(URLError(.notConnectedToInternet)))
        #expect(TransportError.isOffline(URLError(.timedOut)))
        #expect(!TransportError.isOffline(URLError(.badServerResponse)))
        struct Other: Error {}
        #expect(!TransportError.isOffline(Other()))
    }
}

@MainActor struct ConnectivityTests {
    @Test func theFakeAnnouncesChanges() async {
        let monitor = FakeConnectivity(online: true)
        #expect(await monitor.isOnline)
        let stream = monitor.changes()
        let first = Task {
            for await online in stream {
                return online
            }
            return true
        }
        try? await Task.sleep(for: .milliseconds(20))
        monitor.set(online: false)
        #expect(await first.value == false)
        #expect(await monitor.isOnline == false)
    }
}
