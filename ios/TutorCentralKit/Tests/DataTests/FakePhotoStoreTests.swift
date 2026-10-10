import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakePhotoStoreTests {
    @Test func addKeepsThePathUnderTheCentreAndRemoveAllClearsIt() async throws {
        let store = FakePhotoStore()
        let centre = UUID()
        let path = try await store.add(Data([0xFF, 0xD8]), centre: centre, kind: "own")
        #expect(path.hasPrefix("\(centre.uuidString.lowercased())/own/"))
        #expect(path.hasSuffix(".jpg"))
        #expect(store.paths == [path])
        try await store.removeAll(centre: centre)
        #expect(store.paths.isEmpty)
    }
}
