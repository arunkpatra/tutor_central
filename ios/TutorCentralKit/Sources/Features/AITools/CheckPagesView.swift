import Data
import DesignSystem
import Domain
import PhotosUI
import SwiftUI
import UIKit

/// The answer sheet's pages (P6-Check-Pages): two to a row with Remove, Add a page (the document camera) and From
/// Photos; up to six, in order, each reduced on the iPhone. Next opens the marking scheme.
public struct CheckPagesView: View {
    let store: CheckStore
    let openScheme: () -> Void
    @State private var picked: [PhotosPickerItem] = []
    @State private var pickingPhotos = false
    @State private var scanning = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(store: CheckStore, openScheme: @escaping () -> Void) {
        self.store = store
        self.openScheme = openScheme
    }

    private var room: Int {
        CheckStore.maxPages - store.pages.count
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Answer sheet") { dismiss() }
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader(
                        store.pages.count == 1 ? "1 page" : "\(store.pages.count) pages",
                        action: room > 0 ? ("From Photos", { pickingPhotos = true }) : nil
                    )
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.tileGap) {
                        ForEach(Array(store.pages.enumerated()), id: \.offset) { index, page in
                            PageTile(image: UIImage(data: page.data) ?? UIImage(), number: index + 1) {
                                store.removePage(at: index)
                            }
                        }
                        if room > 0 {
                            AddPageTile { scanning = true }
                        }
                    }
                }
                Text("Up to 6 pages, in order. Each page is reduced on this iPhone before it is sent.")
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
        .safeAreaInset(edge: .bottom) {
            FooterButton {
                Button("Next: the marking scheme", action: openScheme)
                    .buttonStyle(.primary(.card))
                    .disabled(store.pages.isEmpty)
            }
        }
        .photosPicker(
            isPresented: $pickingPhotos,
            selection: $picked,
            maxSelectionCount: max(1, room),
            matching: .images
        )
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            picked = []
            Task {
                var uploads: [ImageUpload] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let upload = PhotoReducer.reduce(data) {
                        uploads.append(upload)
                    }
                }
                store.addPages(uploads)
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .fullScreenCover(isPresented: $scanning) {
            DocumentCameraView(maxPages: max(1, room)) { pages in
                scanning = false
                store.addPages(pages.compactMap(PhotoReducer.reduce))
            } onCancel: {
                scanning = false
            }
            .ignoresSafeArea()
        }
    }
}
