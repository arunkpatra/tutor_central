import DesignSystem
import SwiftUI

/// Export on the student's page (P18-Export-Ask, -Making, -Ready, -Failed): a card with a 40 pt tile and the state's
/// row, its buttons under it, the footnote outside; Share opens the system share sheet with the file.
struct ExportSection: View {
    @Bindable var store: ExportStore
    @State private var sharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Export")
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                HStack(alignment: .center, spacing: Tokens.rowPaddingHorizontal) {
                    tile
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(store.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                        Text(store.line)
                            .typeStyle(Tokens.subhead)
                            .foregroundStyle(Tokens.text2.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                buttons
            }
            .padding(.vertical, Tokens.rowPaddingHorizontal)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .surface(radius: Tokens.radiusCard)
            Text(store.footnote)
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Tokens.rowGapInner)
        }
        .onChange(of: store.shared) { _, url in sharing = url != nil }
        .sheet(isPresented: $sharing, onDismiss: store.shareDone) {
            if let url = store.shared {
                ActivitySheet(url: url).presentationDetents([.medium, .large])
            }
        }
        .onDisappear(perform: store.stop)
    }

    @ViewBuilder private var tile: some View {
        switch store.state {
        case .ask: IconTile(symbol: "doc.text")
        case .making: IconTile.working
        case .ready: IconTile(symbol: "doc.text", tint: Tokens.ok, background: Tokens.okTint)
        case .failed: IconTile(symbol: "exclamationmark.circle", tint: Tokens.overdue, background: Tokens.overdueTint)
        }
    }

    @ViewBuilder private var buttons: some View {
        switch store.state {
        case .ask:
            wide("Make the file")
        case .making:
            EmptyView()
        case .ready:
            AdaptiveRow(spacing: Tokens.tileGap, stackedSpacing: Tokens.tileGap) {
                Button("Make again") { Task { await store.make() } }
                    .buttonStyle(.secondary(.form, loading: store.asking))
                    .frame(maxWidth: .infinity)
                Button {
                    Task { await store.share() }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary(.form))
            }
        case .failed:
            wide("Try Again")
        }
    }

    private func wide(_ title: String) -> some View {
        Button {
            Task { await store.make() }
        } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.secondary(.form, loading: store.asking))
    }
}
