import AVFoundation
import Data
import DesignSystem
import PhotosUI
import SwiftUI

extension View {
    /// The system's Take a photo / Choose from Photos, then the document camera or the photos picker; the page reduced
    /// (D36). The camera's access asked first; refused, where to allow it.
    func photoPageChooser(
        isPresented: Binding<Bool>, purpose: String, onPage: @escaping (ImageUpload) -> Void
    ) -> some View {
        modifier(PhotoPageChooser(isPresented: isPresented, purpose: purpose, onPage: onPage))
    }
}

private struct PhotoPageChooser: ViewModifier {
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @Binding var isPresented: Bool
    /// "photograph a report card": the camera-off alert's words.
    let purpose: String
    let onPage: (ImageUpload) -> Void
    @State private var picking = false
    @State private var picked: PhotosPickerItem?
    @State private var scanning = false

    func body(content: Content) -> some View {
        content
            .confirmationDialog("From a photo", isPresented: $isPresented, titleVisibility: .hidden) {
                Button("Take a photo", action: takePhoto)
                Button("Choose from Photos") { picking = true }
            }
            .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
            .onChange(of: picked) { _, item in
                guard let item else { return }
                picked = nil
                Task { await readPicked(item) }
            }
            .fullScreenCover(isPresented: $scanning) {
                DocumentCameraView(maxPages: 1) { pages in
                    scanning = false
                    if let page = pages.first, let upload = PhotoReducer.reduce(page) {
                        onPage(upload)
                    }
                } onCancel: {
                    scanning = false
                }
                .ignoresSafeArea()
            }
    }

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
        case .noCamera: notices?.show(CameraAccess.noCameraMessage)
        }
    }

    private func showRefused() {
        notices?.cameraOff(to: purpose, otherwise: "You can also choose a photo you already have.")
    }

    private func readPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let upload = PhotoReducer.reduce(data) else {
            notices?.show("Couldn't read that picture. Try another photo.")
            return
        }
        onPage(upload)
    }
}
