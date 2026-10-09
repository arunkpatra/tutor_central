import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI
import UIKit

/// What a launch state sets up on Check a paper (P6-Check-*).
public enum CheckBoardState: Hashable, Sendable {
    case typed, markPicker, edited, saved
    /// The edited marks opened at their end, so the glass under the status bar shows (U24, P8-Check-Marks-Scrolled).
    case scrolled
}

/// Check a paper's intro (P6-Check-Intro), pushed from More: the student (a picker), the notice, Take photos (the
/// document camera, up to six pages) and Choose from Photos. The consent sheet comes first for a centre that has not
/// agreed. Pages chosen open the Answer sheet.
public struct CheckIntroView: View {
    let store: CheckStore
    let openPages: () -> Void
    @State private var picked: [PhotosPickerItem] = []
    @State private var scanning = false
    @State private var pickingStudent = false
    @State private var consent = false
    @State private var pending: [ImageUpload] = []
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    public init(store: CheckStore, openPages: @escaping () -> Void) {
        self.store = store
        self.openPages = openPages
    }

    static let notice = NoticesCard.Notice(
        symbol: "lock", text: "The photos go to our AI service to be read and are not kept, there or here."
    )

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Check a paper") { dismiss() }
                IntroHero(
                    symbol: "doc.text.magnifyingglass", title: "Suggested marks for an answer sheet",
                    line: "Photograph each page of a student's answer sheet. With the marking scheme, we suggest a "
                        + "mark for every question. You decide each mark before anything is saved."
                )
                Card(.hero) {
                    VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                        PickerTile(label: "Student", value: store.student?.name ?? "Choose a student") {
                            pickingStudent = true
                        }
                        if let student = store.student {
                            Text(store.register.classroom(student.classID)?.name ?? "No class")
                                .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                                .padding(.horizontal, Tokens.fieldGap)
                        }
                    }
                }
                NoticesCard([Self.notice])
                VStack(spacing: Tokens.rowPaddingDense) {
                    Button(action: takePhotos) { Label("Take photos", systemImage: "camera") }
                        .buttonStyle(.primary(.card))
                    PhotosPicker(selection: $picked, maxSelectionCount: CheckStore.maxPages, matching: .images) {
                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.secondary(.card))
                }
                .disabled(store.student == nil)
                Text("AI can make mistakes. Every mark is a suggestion until you save it.")
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.prepare() }
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            picked = []
            Task { await readPicked(items) }
        }
        .fullScreenCover(isPresented: $scanning) {
            DocumentCameraView(maxPages: CheckStore.maxPages) { pages in
                scanning = false
                start(pages.compactMap(PhotoReducer.reduce))
            } onCancel: {
                scanning = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $pickingStudent) {
            StudentPickerSheet(
                students: store.register.activeStudents, chosen: store.studentID,
                className: { store.register.classroom($0)?.name },
                pick: { id in
                    store.studentID = id
                    pickingStudent = false
                },
                close: { pickingStudent = false }
            )
        }
        .sheet(isPresented: $consent) {
            ConsentSheet(centreName: store.workspace.centre.name) {
                let agreed = await store.recordConsent()
                if agreed {
                    consent = false
                    store.addPages(pending)
                    pending = []
                    openPages()
                }
                return agreed
            } close: {
                consent = false
                pending = []
            }
        }
    }

    private func takePhotos() {
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

    private func readPicked(_ items: [PhotosPickerItem]) async {
        var uploads: [ImageUpload] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let upload = PhotoReducer.reduce(data) {
                uploads.append(upload)
            }
        }
        if uploads.count < items.count {
            toasts?.show("Couldn't read that picture.")
        }
        start(uploads)
    }

    private func start(_ uploads: [ImageUpload]) {
        guard !uploads.isEmpty else { return }
        if store.needsConsent {
            pending = uploads
            consent = true
        } else {
            store.addPages(uploads)
            openPages()
        }
    }
}
