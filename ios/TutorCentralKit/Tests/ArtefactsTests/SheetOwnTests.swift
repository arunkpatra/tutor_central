import Data
import Domain
import Foundation
import Testing
import UIKit
@testable import Artefacts

/// Use my own (P10-Sheet-OwnMenu, -Own; plan decision 13).
@MainActor struct SheetOwnTests {
    /// A JPEG of the width asked, as a camera would give.
    static func jpeg(width: CGFloat) -> Data {
        let size = CGSize(width: width, height: width * 1.4)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 1) ?? Data()
    }

    @Test func aPhotoIsReducedUploadedKeptAndLinkedInPlaceOfTheSheet() async throws {
        let plans = FakePlansRepository.evening(), photos = FakePhotoStore()
        let store = try await SheetStoreTests().store(plans: plans, photos: photos)
        let made = try #require(store.artefact?.id)
        await store.useOwn(photo: Self.jpeg(width: 3000))
        #expect(photos.paths.count == 1)
        #expect(photos.paths.first?.contains("/own/") == true)
        #expect(photos.lastBytes < 1_500_000)
        #expect(store.artefact?.source == .own)
        #expect(store.artefact?.photoPath == photos.paths.first)
        #expect(store.title == "Your sheet · balancing equations")
        #expect(store.line == "A photo · added today, 16:40 · for Dev, Meher and Nikhil")
        #expect(store.inPlaceLine == "Used in place of sheet 1. The plan and the record treat it as sheet 1: "
            + "homework given, done, not done.")
        let plan = try #require(try await ArtefactTest.plan(plans))
        #expect(plan.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy {
            $0.artefactID == store.artefact?.id
        })
        await store.useMadeInstead()
        #expect(store.artefact?.id == made)
    }

    @Test func replacingYourOwnSheetKeepsTheMadeSheetsWords() async throws {
        let store = try await SheetStoreTests().store()
        let made = try #require(store.artefact?.id)
        await store.useOwn(photo: Self.jpeg(width: 1200))
        await store.useOwn(text: "1. Balance Fe + O2")
        #expect(store.title == "Your sheet · balancing equations")
        #expect(store.ownContent?.inPlaceOf == "sheet 1")
        #expect(store.artefact?.regeneratedFrom == made)
    }

    @Test func typedWordsBecomeAnOwnSheetWithNoPhoto() async throws {
        let store = try await SheetStoreTests().store()
        await store.useOwn(text: "1. Balance Fe + O2\n2. Balance Mg + O2")
        #expect(store.artefact?.source == .own)
        #expect(store.artefact?.photoPath == nil)
        guard case let .own(own)? = store.artefact?.content else { Issue.record("not own")
            return
        }
        #expect(own.text?.hasPrefix("1. Balance") == true)
    }

    @Test func ownOfflineIsRefusedAndNothingUploads() async throws {
        let photos = FakePhotoStore()
        let store = try await SheetStoreTests().store(photos: photos)
        store.online = { false }
        await store.useOwn(photo: Self.jpeg(width: 800))
        #expect(photos.paths.isEmpty)
        #expect(store.message == OfflineRefusal.words(for: .ownSheet))
    }
}
