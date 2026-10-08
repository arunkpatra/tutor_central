import DesignSystem
import Domain
import SwiftUI

/// P5-Reports-Export: which file to share, its name and its columns, then the system share sheet with the CSV.
struct ExportSheet: View {
    let store: ReportsStore
    let onMessage: (String) -> Void
    let close: () -> Void
    @State private var chosen: ReportsStore.Segment
    @State private var file: URL?
    /// The board's sheet starts 440 pt down an 852 pt screen.
    static let boardFraction = 0.56

    init(
        store: ReportsStore,
        initial: ReportsStore.Segment,
        onMessage: @escaping (String) -> Void,
        close: @escaping () -> Void
    ) {
        self.store = store
        self.onMessage = onMessage
        self.close = close
        _chosen = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Share as CSV", cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                Text(
                    "A spreadsheet of \(store.monthTitle), one row per student. "
                        + "Opens in Numbers, Files or anywhere a CSV goes."
                )
                .typeStyle(Tokens.subhead)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: Tokens.tileGap) {
                    ChoiceCard(
                        title: "Fees",
                        line: "\(FeesCSV.fileName(store.month)) · "
                            + "Student, class, amount, status, paid on, paid by, reminded on",
                        selected: chosen == .fees
                    ) { chosen = .fees }
                    ChoiceCard(
                        title: "Attendance",
                        line: "\(AttendanceCSV.fileName(store.month)) · Student, class, present, absent, percentage",
                        selected: chosen == .attendance
                    ) { chosen = .attendance }
                }
            }
            Spacer(minLength: 0)
            share
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .presentationDetents([.fraction(Self.boardFraction), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
        .task(id: chosen) { write() }
    }

    @ViewBuilder private var share: some View {
        let name = chosen == .fees ? FeesCSV.fileName(store.month) : AttendanceCSV.fileName(store.month)
        if let file {
            ShareLink(item: file, preview: SharePreview(name)) {
                Label("Share \(name)", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.primary(.sheet))
            .environment(\.buttonIconSize, Tokens.iconSmall)
        } else {
            Button {} label: { Label("Share \(name)", systemImage: "square.and.arrow.up") }
                .buttonStyle(.primary(.sheet))
                .environment(\.buttonIconSize, Tokens.iconSmall)
                .disabled(true)
        }
    }

    /// The chosen file, written for the share sheet; a write that fails says so.
    private func write() {
        file = store.exportFile(chosen)
        if file == nil {
            onMessage("Couldn't write the file.")
        }
    }
}
