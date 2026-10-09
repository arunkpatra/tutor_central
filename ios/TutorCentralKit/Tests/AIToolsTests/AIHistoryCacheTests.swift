import Data
import Domain
import Foundation
import Testing
@testable import AITools

@MainActor struct AIHistoryCacheTests {
    @Test func offlineTheSavedHistoryShows() async {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ai-\(UUID().uuidString)")
        let centre = FakeCentreRepository.meeraWorkspaceConsented.centre.id
        let history = FakeAIHistoryRepository(generations: FakeAIHistoryRepository.seed)
        let first = await AIStoreTests.make(history: history)
        first.historyCache = CachedRead(centre: centre, key: "ai-history", directory: folder)
        await first.loadHistory()
        history.nextError = URLError(.notConnectedToInternet)
        let offline = await AIStoreTests.make(history: history)
        offline.historyCache = CachedRead(centre: centre, key: "ai-history", directory: folder)
        await offline.loadHistory()
        #expect(offline.history.count == FakeAIHistoryRepository.seed.count && offline.historySavedAt != nil)
        #expect(offline.historyOfflineRead && offline.historyError == nil)
    }
}
