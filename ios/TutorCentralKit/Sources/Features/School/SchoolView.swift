import AVFoundation
import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI

/// What a launch state sets up on the School root so it can be photographed beside its board.
public enum SchoolBoardState: Sendable {
    case addMenu
    case calendar(Day)
    /// The tab filtered to a student (P14-School-Student).
    case filtered(UUID)
}

/// The School tab (P10-School-Empty, -List, -Calendar, -AddMenu): the title with the "+" menu, List | Calendar, the
/// items by week or the month with dots and the chosen day's items; the empty card; the copy offline under the status
/// line; a failed first read in its place.
public struct SchoolView: View {
    @Bindable var store: SchoolStore
    let actions: SchoolActions
    let boardState: SchoolBoardState?
    let status: StatusFor
    @State private var showsMenu = false
    @State private var choosingPhoto = false
    @State private var picking = false
    @State private var picked: PhotosPickerItem?
    @State private var scanning = false
    @State private var topInset: CGFloat = 0
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(
        store: SchoolStore, actions: SchoolActions, boardState: SchoolBoardState? = nil,
        status: @escaping StatusFor = { _, _ in .online }
    ) {
        self.store = store
        self.actions = actions
        self.boardState = boardState
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                titleRow
                if let line = status(store.savedAt, store.offlineRead).line {
                    StatusLine(line)
                }
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
        .refreshable {
            await store.refresh()
            Haptic.play(.impactLight)
        }
        .task {
            await store.load()
            setUpBoardState()
        }
        .confirmationDialog("From a photo", isPresented: $choosingPhoto, titleVisibility: .hidden) {
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
                    actions.read(.photo(upload))
                }
            } onCancel: {
                scanning = false
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .loading:
            EmptyView()
        case .failed:
            LoadFailedView("Couldn't load what the schools sent.") { Task { await store.refresh() } }
        case .empty:
            SchoolEmptyCard(askParents: actions.askParents, fromPhoto: { choosingPhoto = true })
        case .items, .offline:
            Segmented(options: [(SchoolStore.Segment.list, "List"), (.calendar, "Calendar")], selection: $store.segment)
            if let chip = store.filterChip {
                FilterChipRow(chip, initials: store.filterInitials, clear: ("Show all", store.showAll))
            }
            switch store.segment {
            case .list: SchoolList(buckets: store.buckets, open: actions.openItem)
            case .calendar: SchoolCalendarSection(store: store, open: actions.openItem)
            }
            if let line = store.filterLine {
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var titleRow: some View {
        HStack(alignment: .bottom) {
            Text("School")
                .typeStyle(Tokens.display)
                .singleLineTitle()
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Tokens.inline)
            Button { showsMenu = true } label: { IconButtonLook(symbol: "plus") }
                .pressable()
                .accessibilityLabel("Add")
                .popover(isPresented: $showsMenu, arrowEdge: .top) {
                    SchoolAddMenu(
                        fromPhoto: { menuChose { choosingPhoto = true } },
                        paste: { menuChose(paste) },
                        byHand: { menuChose { actions.read(.typed) } },
                        askParents: { menuChose(actions.askParents) }
                    )
                    .presentationCompactAdaptation(.popover)
                }
        }
    }

    private func menuChose(_ action: @escaping () -> Void) {
        showsMenu = false
        action()
    }

    /// Paste a message (U41): the read screen waits for the system's Paste button, so iOS asks nothing.
    private func paste() {
        actions.read(.pasteWaiting)
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
        notices?.cameraOff(
            to: "photograph what the school sent",
            otherwise: "You can also choose a photo you already have."
        )
    }

    private func readPicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let upload = PhotoReducer.reduce(data) else {
            notices?.show("Couldn't read that picture. Try another photo.")
            return
        }
        actions.read(.photo(upload))
    }

    private func setUpBoardState() {
        switch boardState {
        case .addMenu:
            showsMenu = true
        case let .calendar(day):
            store.segment = .calendar
            store.selectedDay = day
        case let .filtered(student):
            store.filter = student
        case nil:
            break
        }
    }
}
