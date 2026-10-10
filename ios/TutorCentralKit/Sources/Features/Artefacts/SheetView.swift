import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI

/// What a launch state sets up on an artefact: a sheet's (P10-Sheet-Key, -Board, -Regenerate, -Regenerating, -OwnMenu)
/// or the worked example's second step shown (P10-WorkedExample).
public enum ArtefactBoardState: Hashable, Sendable {
    case key
    case board
    case reasons
    case regenerating
    case ownMenu
    case secondStep
}

/// A sheet (P10-Sheet, dark and light; -Key; -Board), made again (-Regenerate, -Regenerating), or the tutor's own in
/// its place (-OwnMenu, -Own): the nav row with Use my own (Replace for the tutor's own), the hero, Paper | Board |
/// Key,
/// the sheet; the footer band with the AI line, Make it again, Share as PDF and Print.
struct SheetView: View {
    enum Menu { case reasons, own }

    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State private var store: SheetStore
    let actions: ArtefactsActions
    let boardState: ArtefactBoardState?
    @State private var topInset: CGFloat = 0
    @State private var pdf: URL?
    @State private var menu: Menu?
    @State private var askingReason = false
    @State private var typing = false
    @State private var scanning = false
    @State private var picking = false
    @State private var picked: PhotosPickerItem?

    init(store: SheetStore, actions: ArtefactsActions, boardState: ArtefactBoardState?) {
        _store = State(initialValue: store)
        self.actions = actions
        self.boardState = boardState
    }

    private var isOwn: Bool {
        store.artefact?.source == .own
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Sheet", action: (isOwn ? "Replace" : "Use my own", { menu = .own })) { dismiss() }
                content
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
        .safeAreaInset(edge: .bottom) {
            if store.artefact != nil {
                SheetFooter(store: store, pdf: pdf) { menu = .reasons }
            }
        }
        .overlay { menuOverlay }
        .fullScreenCover(isPresented: Binding(
            get: { store.form == .board && store.sheet != nil },
            set: {
                if !$0 {
                    store.form = .paper
                }
            }
        )) {
            SheetBoard(store: store)
        }
        .fullScreenCover(isPresented: $scanning) {
            DocumentCameraView(maxPages: 1) { pages in
                scanning = false
                if let page = pages.first?.jpegData(compressionQuality: 1) {
                    Task { await store.useOwn(photo: page) }
                }
            } onCancel: {
                scanning = false
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $picking, selection: $picked, matching: .images)
        .onChange(of: picked) { _, item in
            guard let item else { return }
            picked = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await store.useOwn(photo: data)
                } else {
                    notices?.show("Couldn't read that picture. Try another photo.")
                }
            }
        }
        .sheet(isPresented: $askingReason) {
            ReasonSheet(onMake: { words in
                askingReason = false
                Task { await store.makeAgain(.own(words)) }
            }, onClose: { askingReason = false })
        }
        .sheet(isPresented: $typing) {
            TypeItSheet(onKeep: { text in
                typing = false
                Task { await store.useOwn(text: text) }
            }, onClose: { typing = false })
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task {
            await store.load()
            setUpBoard()
        }
        .task(id: PDFKey(form: store.form, artefact: store.artefact?.id, image: store.ownImage?.count)) {
            pdf = try? PDFMaker.pdf(for: store.pdfSheet)
        }
    }

    @ViewBuilder private var content: some View {
        if let failed = store.loadFailed {
            Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
        } else if store.artefact != nil {
            ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.line)
            if isOwn {
                OwnSheetBody(store: store)
            } else {
                Segmented(options: [(.paper, "Paper"), (.board, "Board"), (.key, "Key")], selection: $store.form)
                SheetBody(store: store)
            }
        } else {
            Card { SkeletonRow() }
        }
    }

    @ViewBuilder private var menuOverlay: some View {
        switch menu {
        case .reasons?:
            GlassMenu(eyebrow: "Make it again", rows: reasonRows, alignment: .bottom) { menu = nil }
        case .own?:
            GlassMenu(
                eyebrow: nil, rows: ownRows, alignment: .topTrailing, top: Tokens.pageTop + Tokens.rowPaddingDense
            ) { menu = nil }
        case nil:
            EmptyView()
        }
    }

    private var reasonRows: [GlassMenuRow] {
        let reasons: [(String, RegenerateReason)] = [
            ("Easier", .easier), ("Harder", .harder), ("Shorter", .shorter), ("More sums", .moreSums),
            ("Different numbers", .differentNumbers),
        ]
        return reasons.map { label, reason in
            GlassMenuRow(label: label, symbol: nil) { Task { await store.makeAgain(reason) } }
        } + [GlassMenuRow(label: "Say what to change…", symbol: nil) { askingReason = true }]
    }

    private var ownRows: [GlassMenuRow] {
        [
            GlassMenuRow(label: "Take a photo", symbol: "camera", action: takePhoto),
            GlassMenuRow(label: "Choose from Photos", symbol: "photo.on.rectangle") { picking = true },
            GlassMenuRow(label: "Type it", symbol: "pencil.line") { typing = true },
        ]
    }

    /// The camera after its access (DesignSystem's `CameraAccess`), as Add a textbook asks.
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
        notices?.cameraOff(to: "photograph your sheet", otherwise: "You can also choose a photo you already have.")
    }

    private func setUpBoard() {
        switch boardState {
        case .key: store.form = .key
        case .board:
            store.form = .board
            store.boardIndex = 2
        case .reasons: menu = .reasons
        case .regenerating: Task { await store.makeAgain(.easier) }
        case .ownMenu: menu = .own
        case .secondStep, nil: break
        }
    }
}

/// What the PDF is made from: the form, the artefact, the tutor's photo once loaded.
private struct PDFKey: Hashable {
    let form: SheetStore.Form
    let artefact: UUID?
    let image: Int?
}
