import Foundation
import Testing
@testable import Data

struct QRImageStoreTests {
    @Test func theMemoryStoreKeepsOneImagePerCentre() throws {
        let store = MemoryQRImageStore()
        let centre = UUID()
        try store.save(Data([1, 2, 3]), for: centre)
        #expect(store.image(for: centre) == Data([1, 2, 3]) && store.image(for: UUID()) == nil)
        store.remove(for: centre)
        #expect(store.image(for: centre) == nil && store.images.isEmpty)
    }

    @Test func theFileStoreRoundTripsAndRemoves() throws {
        let store = FileQRImageStore()
        let centre = UUID()
        try store.save(Data([7, 8, 9]), for: centre)
        #expect(store.image(for: centre) == Data([7, 8, 9]))
        store.remove(for: centre)
        #expect(store.image(for: centre) == nil)
        store.remove(for: centre)
    }
}
