import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on a sheet (P10-Sheet-Key, -Board, and Task 17's).
public enum SheetBoardState: Hashable, Sendable {
    case key
    case board
}

/// A sheet (P10-Sheet, dark and light; -Key; -Board): the nav row with Use my own, the hero, Paper | Board | Key, the
/// sheet as Paper or Key, the board full screen; the footer band with the AI line, Make it again, Share as PDF and
/// Print.
struct SheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: SheetStore
    let actions: ArtefactsActions
    let boardState: SheetBoardState?
    @State private var topInset: CGFloat = 0
    @State private var pdf: URL?

    init(store: SheetStore, actions: ArtefactsActions, boardState: SheetBoardState?) {
        _store = State(initialValue: store)
        self.actions = actions
        self.boardState = boardState
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Sheet", action: ("Use my own", {})) { dismiss() }
                if let failed = store.loadFailed {
                    Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
                } else if store.artefact != nil {
                    ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.line)
                    Segmented(options: [(.paper, "Paper"), (.board, "Board"), (.key, "Key")], selection: $store.form)
                    SheetBody(store: store)
                } else {
                    Card { SkeletonRow() }
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
        .safeAreaInset(edge: .bottom) {
            if store.artefact != nil {
                SheetFooter(store: store, pdf: pdf)
            }
        }
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
        .task {
            await store.load()
            switch boardState {
            case .key: store.form = .key
            case .board:
                store.form = .board
                store.boardIndex = 2
            case nil: break
            }
        }
        .task(id: store.form) {
            pdf = try? PDFMaker.pdf(for: store.pdfSheet)
        }
    }
}
