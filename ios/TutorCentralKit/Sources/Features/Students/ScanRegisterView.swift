import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI
import UIKit

/// What a launch state sets up on Scan register (P6-Scan-*).
public enum ScanBoardState: Hashable, Sendable {
    case consent, cameraRefused, reading, review, edit, rowRemoved, leave, nothing, failed
}

/// Scan register (P6-Scan-Intro to -Failed), pushed from More, the Students "+" menu and the empty register: the
/// intro with the notices, the consent before the first photo, the camera or Photos, reading, then the list to check
/// (`ScanReviewView`), nothing found, or a failure with Retry.
public struct ScanRegisterView: View {
    @State private var store: ScanStore
    private let boardState: ScanBoardState?
    private let sample: ImageUpload?
    @State private var picked: PhotosPickerItem?
    @State private var scanning = false
    @State private var consent = false
    @State private var pending: ImageUpload?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    /// `sample` is the fixtures' photo for a board state (the simulator has no camera).
    public init(store: ScanStore, boardState: ScanBoardState? = nil, sample: ImageUpload? = nil) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.sample = sample
        _consent = State(initialValue: boardState == .consent)
    }

    public var body: some View {
        Group {
            if store.stage == .review {
                ScanReviewView(store: store, boardState: boardState) { dismiss() }
            } else {
                screen
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            if let removed = store.removed, message == "\(removed.row.name) removed." {
                toasts?.show(message, action: ("Undo", { store.undoRemove() }))
            } else {
                toasts?.show(message)
            }
            store.message = nil
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            Task { await readPicked(item) }
        }
        .fullScreenCover(isPresented: $scanning) {
            DocumentCameraView(maxPages: 1) { pages in
                scanning = false
                if let page = pages.first, let upload = PhotoReducer.reduce(page) {
                    start(upload)
                }
            } onCancel: {
                scanning = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $consent) {
            ConsentSheet(centreName: store.workspace.centre.name) {
                let agreed = await store.recordConsent()
                if agreed {
                    consent = false
                    if let pending {
                        self.pending = nil
                        store.begin(pending)
                    }
                }
                return agreed
            } close: {
                consent = false
                pending = nil
            }
        }
        .onAppear(perform: setUpBoard)
    }

    private var screen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Scan register") { dismiss() }
                switch store.stage {
                case .reading: reading
                case .nothing: nothing
                case let .failed(message): failed(message)
                case .intro, .review: intro
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    @ViewBuilder private var intro: some View {
        IntroHero(
            symbol: "doc.viewfinder", title: "Read a paper register",
            line: "Take a photo of a page of your register. We read the names, phone numbers and fees into a list you "
                + "check row by row."
        )
        NoticesCard([
            .init(symbol: "lock", text: "The photo goes to our AI service to be read and is not kept, there or here."),
            .init(symbol: "checkmark", text: "Nothing is saved until you have checked every row and tapped Add."),
        ])
        VStack(spacing: Tokens.rowPaddingDense) {
            Button(action: takePhoto) { Label("Take a photo", systemImage: "camera") }.buttonStyle(.primary(.card))
            photosButton
        }
        Text("AI can make mistakes. Check every name and number before you add them.")
            .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            .padding(.horizontal, Tokens.rowGapInner)
    }

    @ViewBuilder private var reading: some View {
        CreatingCard(title: "Reading the register", line: "Usually under a minute.", thumbnail: thumbnail, cancel: nil)
        Button("Cancel") { store.reset() }.buttonStyle(.quiet).frame(maxWidth: .infinity)
    }

    @ViewBuilder private var nothing: some View {
        CreatingCard(
            title: "No names found", line: "Nothing on this photo read as a name.", thumbnail: thumbnail,
            working: false, cancel: nil
        )
        Card {
            EmptyRow(
                symbol: "doc.viewfinder", title: "Try another photo",
                line: "The whole page, straight on, in good light. One page at a time reads best."
            )
        }
        VStack(spacing: Tokens.rowPaddingDense) {
            Button(action: takePhoto) { Label("Take another photo", systemImage: "camera") }
                .buttonStyle(.primary(.card))
            photosButton
        }
    }

    @ViewBuilder
    private func failed(_ message: String) -> some View {
        CreatingCard(
            title: "Reading the register", line: "The photo is still here.", thumbnail: thumbnail, working: false,
            cancel: nil
        )
        ErrorRow(
            title: "Couldn't read the register.",
            line: message == APIFailure.offline.message
                ? "Check your connection and try again. The photo is sent again as it is." : message,
            retry: { Task { await store.retry() } }
        )
        Button(action: takePhoto) { Label("Take another photo", systemImage: "camera") }.buttonStyle(.secondary(.card))
    }

    private var photosButton: some View {
        PhotosPicker(selection: $picked, matching: .images) {
            Label("Choose from Photos", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.secondary(.card))
    }

    private var thumbnail: UIImage? {
        store.photo.flatMap { UIImage(data: $0.data) }
    }

    /// Take a photo: the camera when allowed, the system's question the first time, where to allow it when refused,
    /// and "No camera" in the simulator.
    private func takePhoto() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch CameraAccess.decide(supported: DocumentCameraView.isSupported, status: status) {
        case .scan: scanning = true
        case .ask:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    scanning = true
                } else {
                    showRefused()
                }
            }
        case .denied: showRefused()
        case .noCamera: toasts?.show(CameraAccess.noCameraMessage)
        }
    }

    private func showRefused() {
        toasts?.show(CameraAccess.deniedMessage, action: ("Open Settings", {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
    }

    private func readPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let upload = PhotoReducer.reduce(data) else {
            toasts?.show("Couldn't read that picture.")
            return
        }
        start(upload)
    }

    /// The consent sheet first when the centre has not agreed, else reading at once.
    private func start(_ upload: ImageUpload) {
        if store.needsConsent {
            pending = upload
            consent = true
        } else {
            store.begin(upload)
        }
    }

    private func setUpBoard() {
        guard let boardState, store.stage == .intro else { return }
        switch boardState {
        case .cameraRefused: showRefused()
        case .consent: pending = sample
        case .reading, .review, .edit, .rowRemoved, .leave, .nothing, .failed:
            if let sample {
                store.begin(sample)
            }
        }
    }
}
