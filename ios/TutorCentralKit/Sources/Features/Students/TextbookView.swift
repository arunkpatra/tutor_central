import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI
import UIKit

/// What a launch state sets up on Add a textbook (P10-Textbook-*).
public enum TextbookBoardState: Hashable, Sendable {
    case reading, chapters, chapterEdit
}

/// Add a textbook (P10-Textbook-Intro, -Reading, -Chapters, -Chapter-Edit), pushed from the student's page: the intro
/// with the subject, the notices and the camera or Photos; reading over the intro dimmed; the chapters read, each
/// opened
/// in its sheet; Keep in the footer.
public struct TextbookView: View {
    @State private var store: TextbookStore
    private let boardState: TextbookBoardState?
    private let sample: ImageUpload?
    @State private var picked: PhotosPickerItem?
    @State private var scanning = false
    @State private var choosingSubject = false
    @State private var editing: ChapterEdit?
    @State private var thumbnail: UIImage?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(store: TextbookStore, boardState: TextbookBoardState? = nil, sample: ImageUpload? = nil) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.sample = sample
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: isChecking ? "Check the chapters" : "Add a textbook") { leave() }
                if isChecking {
                    chapters
                } else {
                    if store.phase == .reading {
                        CreatingCard(
                            title: "Reading the contents page",
                            line: store.readingLine,
                            portrait: thumbnail
                        ) {
                            store.cancel()
                        }
                    }
                    intro.opacity(store.phase == .reading ? Tokens.opacityDisabled : 1)
                        .disabled(store.phase == .reading)
                }
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isChecking {
                FooterButton { keepFooter }
            }
        }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            Task { await readPicked(item) }
        }
        .onChange(of: store.failure) { _, failure in
            guard let failure else { return }
            notices?.show(failure)
            store.failure = nil
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
        .sheet(isPresented: $choosingSubject) {
            SubjectSheet(store: store) { choosingSubject = false }
        }
        .sheet(item: $editing) { edit in chapterSheet(edit) }
        .task {
            await store.load()
            await setUpBoard()
        }
    }

    private var isChecking: Bool {
        store.phase == .chapters || store.phase == .keeping
    }

    @ViewBuilder private var intro: some View {
        IntroHero(symbol: "book", title: "Photograph the contents page", line: store.introLine)
        PickerField(label: "Subject", value: store.subject, placeholder: "Choose", helper: store.subjectHelper) {
            choosingSubject = true
        }
        NoticesCard([
            .init(
                symbol: "lock",
                text: "The photo goes to our AI service to be read. We keep no copy; the service deletes it within 30 "
                    + "days."
            ),
            .init(symbol: "book", text: "Only the chapter names are kept, nothing from inside the book."),
            .init(symbol: "checkmark", text: "Nothing is saved until you have checked the list and tapped Keep."),
        ])
        VStack(spacing: Tokens.rowPaddingDense) {
            Button(action: takePhoto) { Label("Take a photo", systemImage: "camera") }
                .buttonStyle(.primary(.card))
                .disabled(!store.canRead)
            PhotosPicker(selection: $picked, matching: .images) {
                Label("Choose from Photos", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.secondary(.card))
            .disabled(!store.canRead)
        }
        Text("AI can make mistakes. Check every chapter before you keep them.")
            .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            .padding(.horizontal, Tokens.rowGapInner)
    }

    @ViewBuilder private var chapters: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            PickerTile(label: "Subject", value: store.subject ?? "") { choosingSubject = true }
            FieldHelper(store.sourceLine)
        }
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.chaptersTitle, action: ("Add a chapter", { editing = .new(store.chapters.count + 1) }))
            Card {
                VStack(spacing: 0) {
                    ForEach(Array(store.chapters.enumerated()), id: \.offset) { index, chapter in
                        ChapterRow(
                            position: chapter.position, name: chapter.name, line: TextbookStore.skillsLine(chapter),
                            open: false
                        ) { editing = .existing(index) }
                            .rowDivider()
                    }
                }
            }
        }
    }

    @ViewBuilder private func chapterSheet(_ edit: ChapterEdit) -> some View {
        switch edit {
        case let .existing(index) where store.chapters.indices.contains(index):
            let chapter = store.chapters[index]
            ChapterSheet(
                position: chapter.position, initialName: chapter.name, initialSkills: chapter.skills,
                onSave: { name, skills in
                    store.rename(at: index, to: name)
                    store.setSkills(at: index, skills)
                },
                onRemove: { store.remove(at: index) }, close: { editing = nil }
            )
        case let .new(position):
            ChapterSheet(
                position: position, initialName: "", initialSkills: [],
                onSave: { store.add(name: $0, skills: $1) }, onRemove: nil, close: { editing = nil }
            )
        default:
            EmptyView()
        }
    }

    private var keepFooter: some View {
        VStack(spacing: Tokens.inline) {
            Button(store.keepTitle) {
                Task {
                    if await store.keep() {
                        dismiss()
                    }
                }
            }
            .buttonStyle(.primary(.card, loading: store.phase == .keeping))
            .disabled(store.chapters.isEmpty)
            Text("Open a chapter to change its name or skills, or remove it. Nothing is kept until you tap Keep.")
                .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
        }
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
        case .noCamera: notices?.show(CameraAccess.noCameraMessage)
        }
    }

    private func showRefused() {
        notices?.cameraOff(to: "photograph a contents page", otherwise: "You can also choose a photo you already have.")
    }

    private func readPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let upload = PhotoReducer.reduce(data) else {
            notices?.show("Couldn't read that picture. Try another photo.")
            return
        }
        start(upload)
    }

    private func start(_ upload: ImageUpload) {
        thumbnail = UIImage(data: upload.data)
        store.begin(upload)
    }

    private func leave() {
        store.cancel()
        dismiss()
    }

    private func setUpBoard() async {
        guard let boardState, let sample else { return }
        switch boardState {
        case .reading: start(sample)
        case .chapters, .chapterEdit:
            thumbnail = UIImage(data: sample.data)
            await store.read(sample, thumbnail: nil)
            if boardState == .chapterEdit {
                editing = .existing(3)
            }
        }
    }
}
