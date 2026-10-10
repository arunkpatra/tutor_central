import Data
import DesignSystem
import Domain
import SwiftUI

/// The list to check (P6-Scan-Review, -Edit, -RowRemoved, -Leave): "Add to" (a class or No class), N found with Add a
/// row, one row per name read (ticked unless already here), Fix this row on a tap, and Add N students in the footer.
/// Back asks before the names are lost; nothing is saved before Add.
struct ScanReviewView: View {
    @Bindable var store: ScanStore
    let boardState: ScanBoardState?
    let leave: () -> Void
    @State private var fixing: ScanRow?
    @State private var leaving = false
    @State private var topInset: CGFloat = 0
    @State private var boardApplied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Check the list", back: back)
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Menu {
                        Button("No class") { store.classID = nil }
                        ForEach(store.register.activeClasses) { classroom in
                            Button(classroom.name) { store.classID = classroom.id }
                        }
                    } label: {
                        PickerTile(label: "Add to", value: store.className ?? "No class") {}
                    }
                    .accessibilityLabel("Add to, \(store.className ?? "No class")")
                    Text("Everyone ticked joins this batch. A fee read from the page stays as the student's own.")
                        .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                }
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader(store.title, action: ("Add a row", { fixing = store.addRow() }))
                    Card {
                        VStack(spacing: 0) {
                            ForEach($store.rows) { $row in
                                ReviewRow(
                                    name: row.name, line: line(row),
                                    tonedLead: row.flag == .noNumber ? "No number read" : nil,
                                    chip: row.flag?.chip, included: $row.included
                                ) { fixing = row }
                                    .rowDivider()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        // A launch state cannot scroll by hand (U11): the scrolled board state opens at the end.
        .defaultScrollAnchor(boardState == .scrolled ? .bottom : nil)
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .overlay {
            if leaving {
                ZStack {
                    Tokens.dim.color.ignoresSafeArea().onTapGesture { leaving = false }
                    DialogView(
                        title: "Leave without adding?",
                        message: "The names read from the photo will be lost. Nothing has been saved.",
                        cancel: "Keep checking", action: "Leave", destructive: false,
                        onCancel: { leaving = false },
                        onAction: leave
                    )
                    .padding(.horizontal, Tokens.pageSide)
                }
                .transition(.opacity)
            }
        }
        .sheet(item: $fixing) { row in fixSheet(row) }
        .onAppear(perform: applyBoard)
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text("Nothing is saved until you add them. Tap a row to fix it; untick one to leave it out.")
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    Task { _ = await store.add() }
                } label: {
                    Label(store.addLabel, systemImage: "person.badge.plus")
                }
                .buttonStyle(.primary(.card, loading: store.adding))
                .disabled(!store.canAdd)
            }
        }
    }

    private func fixSheet(_ row: ScanRow) -> some View {
        FixRowSheet(row: row, store: store, showsFocus: boardState == .edit) { discardIfBlank(row) } remove: {
            fixing = nil
            store.remove(row.id)
        }
    }

    /// A row added by hand and closed without a name goes again.
    private func discardIfBlank(_ row: ScanRow) {
        fixing = nil
        if let kept = store.rows.first(where: { $0.id == row.id }), kept.name.isEmpty {
            store.rows.removeAll { $0.id == row.id }
        }
    }

    private func line(_ row: ScanRow) -> String {
        if case .alreadyHere = row.flag {
            return row.flag?.line ?? row.line
        }
        return row.line
    }

    private func back() {
        if store.hasRows {
            leaving = true
        } else {
            leave()
        }
    }

    private func applyBoard() {
        guard !boardApplied, let boardState else { return }
        boardApplied = true
        switch boardState {
        case .edit: fixing = store.rows.first { $0.name == "Kavya Nair" }
        case .rowRemoved: store.rows.first { $0.name == "Kavya Nair" }.map { store.remove($0.id) }
        case .leave: leaving = true
        default: break
        }
    }
}
