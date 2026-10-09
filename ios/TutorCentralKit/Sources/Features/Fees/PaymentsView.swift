import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI

/// What a launch state sets up on Parent payments: the empty field with its focus ring (P5-Payments-Empty), the
/// Saved mark after a save (-Filled), the id read from a kept QR (-QR).
public enum PaymentsBoardState: Hashable, Sendable {
    case empty
    case saved
    case fromQR
}

/// Parent payments (P5-Payments-Empty, -Filled, -QR), pushed from Settings and from Fees' Payments: the UPI id with
/// Scan a QR and From Photos, the kept QR, the payment link and the receipts switch, each saved as you go.
public struct PaymentsView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: PaymentsStore
    private let boardState: PaymentsBoardState?
    private let onMessage: (String) -> Void
    @State private var picked: PhotosPickerItem?
    @State private var scanning = false
    @State private var topInset: CGFloat = 0
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @Environment(\.dismiss) private var dismiss

    public init(
        store: PaymentsStore, boardState: PaymentsBoardState? = nil,
        onWorkspaceChanged: @escaping (Workspace) -> Void, onMessage: @escaping (String) -> Void
    ) {
        store.onWorkspaceChanged = onWorkspaceChanged
        if boardState == .saved || boardState == .fromQR {
            store.saveState = .saved
        }
        if boardState == .fromQR {
            store.fromQR = true
        }
        _store = State(initialValue: store)
        self.boardState = boardState
        self.onMessage = onMessage
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Parent payments") { dismiss() }
                upi
                link
                receipts
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: store.saveState) { _, state in
            if state == .saved {
                Haptic.play(.success)
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            Haptic.play(.error)
            onMessage(message)
            store.message = nil
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task { await readPhoto(item) }
        }
        // A sheet, not a full-screen cover: a swipe down closes the camera when there is no QR to hand (review).
        .sheet(isPresented: $scanning) {
            QRScannerView { payload in
                scanning = false
                Task { _ = await store.applyQR(payload: payload, image: Data()) }
            }
            .ignoresSafeArea()
            .presentationDragIndicator(.visible)
        }
    }

    private var upi: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader("UPI")
                Spacer()
                SaveMark(saving: store.saveState == .saving, saved: store.saveState == .saved)
            }
            Card {
                VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) {
                    TextWell(
                        label: "UPI id", text: $store.upiID, placeholder: "yourname@bank", helper: store.upiHelper,
                        error: store.upiError, numeric: true, keyboard: .emailAddress, capitalisation: .never,
                        showsFocus: boardState == .empty
                    ) { Task { await store.commitUPI() } }
                    if let data = store.qrImage, let image = UIImage(data: data) {
                        QRRow(
                            image: image, title: "QR from your UPI app", line: "Kept on this iPhone to show a parent.",
                            remove: store.removeQR
                        )
                    }
                    HStack(spacing: Tokens.tileGap) {
                        Button(action: scan) { Label("Scan a QR", systemImage: "camera") }
                            .buttonStyle(.secondary())
                        PhotosPicker(selection: $picked, matching: .images) {
                            Label("From Photos", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.secondary())
                    }
                    .environment(\.buttonIconSize, Tokens.iconSmall)
                }
                .padding(Tokens.rowPaddingHorizontal)
            }
        }
    }

    private var link: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Payment link")
            Card {
                TextWell(
                    label: "Payment link", text: $store.paymentLink, placeholder: "https://", optional: true,
                    helper: "Added to reminders when set, for parents who pay by a link.", error: store.linkError,
                    keyboard: .URL, capitalisation: .never
                ) { Task { await store.commitLink() } }
                    .padding(Tokens.rowPaddingHorizontal)
            }
        }
    }

    private var receipts: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Receipts")
            Card {
                HStack(spacing: Tokens.rowPaddingDense) {
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text("Offer a receipt after Mark paid").typeStyle(Tokens.body)
                            .foregroundStyle(Tokens.text.color)
                        Text("A WhatsApp message with the amount, the date and how it was paid.")
                            .typeStyle(Tokens.footnote)
                            .foregroundStyle(Tokens.text2.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Switch(
                        isOn: Binding(
                            get: { store.sendReceipts }, set: { on in Task { await store.setReceipts(on) } }
                        ),
                        label: "Offer a receipt after Mark paid"
                    )
                }
                .padding(.vertical, Tokens.rowPaddingVertical)
                .padding(.horizontal, Tokens.rowPaddingHorizontal)
            }
        }
    }

    /// The camera: asked for the first time; a refusal says where to allow it; the simulator has none and says so.
    private func scan() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch CameraAccess.decide(supported: QRScannerView.isSupported, status: status) {
        case .scan: scanning = true
        case .ask:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    scanning = true
                } else {
                    notices?.cameraOff(to: "scan your UPI QR", otherwise: "You can also choose a picture of it.")
                }
            }
        case .denied:
            notices?.cameraOff(to: "scan your UPI QR", otherwise: "You can also choose a picture of it.")
        case .noCamera: onMessage(CameraAccess.noCameraMessage)
        }
    }

    /// A picture from Photos: its QR read on this iPhone, the payee filled, the picture kept.
    private func readPhoto(_ item: PhotosPickerItem) async {
        defer { picked = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)?.cgImage else {
            onMessage("Couldn't read that picture. Try another photo.")
            return
        }
        guard let payload = QRDecoder.payload(in: image) else {
            onMessage("No QR found in that picture.")
            return
        }
        _ = await store.applyQR(payload: payload, image: data)
    }
}
