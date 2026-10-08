import Data
import Domain
import Foundation
import Testing
@testable import Fees

@MainActor struct PaymentsStoreTests {
    let centres = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
    let images = MemoryQRImageStore()

    func make(_ workspace: Workspace = FakeCentreRepository.meeraWorkspace) -> PaymentsStore {
        PaymentsStore(workspace: workspace, centres: centres, qrImages: images)
    }

    @Test func theFieldsStartFromTheCentre() {
        let store = make()
        #expect(store.upiID == "meera@okhdfcbank" && store.paymentLink == "" && store.sendReceipts && store
            .saveState == .idle)
        #expect(store.upiHelper == "Reminders tell parents to pay this id." && store.qrImage == nil)
        #expect(make(FakeCentreRepository.meeraWorkspaceWithoutUPI).upiID == "")
    }

    @Test func aChangedIDClearsTheConfirmation() async {
        let store = make()
        var changed: Workspace?
        store.onWorkspaceChanged = { changed = $0 }
        store.upiID = " Meera@YBL "
        await store.commitUPI()
        #expect(centres.upiUpdates == ["meera@ybl"] && store.upiID == "meera@ybl" && store.saveState == .saved)
        #expect(changed?.centre.payments.upiID == "meera@ybl" && changed?.centre.payments.upiConfirmedAt == nil)
        await store.commitUPI()
        #expect(centres.upiUpdates.count == 1, "unchanged: no write")
        store.upiID = ""
        await store.commitUPI()
        #expect(centres.upiUpdates == ["meera@ybl", nil] && changed?.centre.payments.upiID == nil)
    }

    @Test func aBadIDIsRefusedInWordsAndNotWritten() async {
        let store = make()
        store.upiID = "meera"
        await store.commitUPI()
        #expect(store.upiError == "A UPI id looks like name@bank." && centres.upiUpdates.isEmpty && store
            .saveState == .idle)
        store.upiID = "meera@ybl"
        #expect(store.upiError == nil, "typing clears the error")
    }

    @Test func theLinkAndReceiptsSave() async {
        let store = make()
        store.paymentLink = "pay.example/meera"
        await store.commitLink()
        #expect(store.linkError == "A link starts with https://." && centres.linkUpdates.isEmpty)
        store.paymentLink = " https://pay.example/meera "
        await store.commitLink()
        #expect(centres.linkUpdates == ["https://pay.example/meera"] && store.linkError == nil)
        await store.setReceipts(false)
        #expect(centres.receiptUpdates == [false] && !store.sendReceipts)
        centres.nextError = URLError(.notConnectedToInternet)
        await store.setReceipts(true)
        #expect(store.sendReceipts == false && store.message == "Couldn't save. Check your connection and try again.")
    }

    @Test func aQRFillsSavesAndKeepsItsImage() async {
        let store = make(FakeCentreRepository.meeraWorkspaceWithoutUPI)
        let image = Data([0x89, 0x50, 0x4E, 0x47])
        #expect(await store.applyQR(payload: "upi://pay?pa=Meera@OkHdfcBank&pn=Meera", image: image))
        #expect(store.upiID == "meera@okhdfcbank" && centres.upiUpdates == ["meera@okhdfcbank"] && store.fromQR)
        #expect(store.upiHelper == "Read from the QR. Edit it if it is not right." && store.qrImage == image)
        #expect(images.images[FakeCentreRepository.meeraWorkspace.centre.id] == image)
        store.removeQR()
        #expect(
            store.qrImage == nil && images.images.isEmpty && store.upiID == "meera@okhdfcbank",
            "Remove keeps the id"
        )
    }

    @Test func aBadQRIsRefusedInWords() async {
        let store = make()
        #expect(await store.applyQR(payload: "https://example.com/pay", image: Data()) == false)
        #expect(store.message == "That QR is not a UPI QR." && centres.upiUpdates.isEmpty && store.qrImage == nil)
    }
}
