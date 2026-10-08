import Data
import Domain
import Foundation
import Observation

/// Parent payments (P5-Payments-Empty, -Filled, -QR): the UPI id, the payment link and the receipts switch, each saved
/// as you go with the Saved mark (Settings' pattern); a UPI QR from Photos or the camera fills and saves the id, and
/// its image is kept on this iPhone only. Made per screen.
@MainActor @Observable public final class PaymentsStore {
    public enum SaveState: Equatable, Sendable {
        case idle
        case saving
        case saved
    }

    /// The field's text; typing clears its error.
    public var upiID: String {
        didSet { upiError = nil }
    }

    public private(set) var upiError: String?
    public var paymentLink: String {
        didSet { linkError = nil }
    }

    public private(set) var linkError: String?
    public private(set) var sendReceipts: Bool
    public private(set) var saveState: SaveState = .idle
    public var message: String?
    /// The kept QR, read from this iPhone.
    public private(set) var qrImage: Data?
    /// The id came from a QR on this visit: the helper asks the tutor to check it.
    public private(set) var fromQR = false
    public var onWorkspaceChanged: (Workspace) -> Void = { _ in }
    private var workspace: Workspace
    private let centres: any CentreRepository
    private let qrImages: any QRImageStore

    public init(workspace: Workspace, centres: any CentreRepository, qrImages: any QRImageStore) {
        self.workspace = workspace
        self.centres = centres
        self.qrImages = qrImages
        let payments = workspace.centre.payments
        upiID = payments.upiID ?? ""
        paymentLink = payments.paymentLink ?? ""
        sendReceipts = payments.sendReceipts
        qrImage = qrImages.image(for: workspace.centre.id)
    }

    public var upiHelper: String {
        fromQR ? "Read from the QR. Edit it if it is not right." : "Reminders tell parents to pay this id."
    }

    /// Normalised, refused in words when it is not an id; written when it changed. A changed id is unconfirmed again,
    /// so Fees asks "Parents are told to pay …" once more. An empty field clears the id.
    public func commitUPI() async {
        let typed = upiID.trimmingCharacters(in: .whitespacesAndNewlines)
        let id: String?
        if typed.isEmpty {
            id = nil
        } else if let normalised = UPIID.normalised(typed) {
            id = normalised
        } else {
            upiError = UPIID.invalidMessage
            return
        }
        upiID = id ?? ""
        guard id != workspace.centre.payments.upiID else { return }
        let centre = workspace.centre.id
        await save { [centres] in try await centres.updateUPI(id: centre, upiID: id) } apply: {
            $0.centre.payments.upiID = id
            $0.centre.payments.upiConfirmedAt = nil
        }
    }

    /// Trimmed; empty clears it; otherwise it must be a web link.
    public func commitLink() async {
        let typed = paymentLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard typed.isEmpty || typed.hasPrefix("https://") || typed.hasPrefix("http://") else {
            linkError = "A link starts with https://."
            return
        }
        let link = typed.isEmpty ? nil : typed
        paymentLink = typed
        guard link != workspace.centre.payments.paymentLink else { return }
        let centre = workspace.centre.id
        await save { [centres] in try await centres.updatePaymentLink(id: centre, link: link) } apply: {
            $0.centre.payments.paymentLink = link
        }
    }

    /// The switch moves at once and goes back if the write fails.
    public func setReceipts(_ on: Bool) async {
        let before = sendReceipts
        sendReceipts = on
        let centre = workspace.centre.id
        await save { [centres] in try await centres.updateSendReceipts(id: centre, on: on) } apply: {
            $0.centre.payments.sendReceipts = on
        }
        if saveState != .saved {
            sendReceipts = before
        }
    }

    /// A QR's payload and its picture: a UPI QR's payee fills and saves the id, and the picture is kept on this
    /// iPhone (a scan from the camera keeps none). Anything else is refused in words.
    public func applyQR(payload: String, image: Data) async -> Bool {
        guard let id = UPIQR.upiID(in: payload) else {
            message = UPIQR.notUPIMessage
            return false
        }
        upiID = id
        fromQR = true
        await commitUPI()
        if !image.isEmpty {
            try? qrImages.save(image, for: workspace.centre.id)
            qrImage = image
        }
        return true
    }

    /// The picture goes; the id stays.
    public func removeQR() {
        qrImages.remove(for: workspace.centre.id)
        qrImage = nil
        fromQR = false
    }

    private func save(_ write: () async throws -> Void, apply: (inout Workspace) -> Void) async {
        saveState = .saving
        do {
            try await write()
            apply(&workspace)
            onWorkspaceChanged(workspace)
            saveState = .saved
        } catch {
            saveState = .idle
            message = "Couldn't save. Check your connection and try again."
        }
    }
}
