import DesignSystem
import Domain
import SwiftUI

/// A figure (P10-Figure-NumberLine, -FractionBar, -PlaceValue, -UnitCircle, -Triangle, -Cell, -FoodChain): the nav row
/// with Share, the hero with the template's name, the figure card with the model's caption (a tap shows it large), the
/// footer with Show large, Print and the AI line.
struct FigureScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: FigureStore
    @State private var topInset: CGFloat = 0
    @State private var pdf: URL?
    @State private var sharing = false

    init(store: FigureStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Figure", action: pdf == nil ? nil : ("Share", { sharing = true })) { dismiss() }
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
            if store.figure != nil {
                footer
            }
        }
        .fullScreenCover(isPresented: $store.large) { LargeFigure(store: store) }
        .sheet(isPresented: $sharing) {
            if let pdf {
                ActivitySheet(url: pdf).presentationDetents([.medium, .large])
            }
        }
        .task {
            await store.load()
            pdf = makePDF()
        }
    }

    @ViewBuilder private var content: some View {
        if let failed = store.loadFailed {
            Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
        } else if let figure = store.figure {
            ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.line)
            Button { store.large = true } label: {
                FigureCard(caption: figure.caption) { FigureView(spec: figure.figure) }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows it large")
        } else {
            Card { SkeletonRow() }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                HStack(spacing: Tokens.tileGap) {
                    Button { store.large = true } label: { Label("Show large", systemImage: "square.grid.2x2") }
                        .buttonStyle(.secondary(.form))
                    Button {
                        if let pdf {
                            Printer.print(pdf, title: store.title)
                        }
                    } label: { Label("Print", systemImage: "printer") }
                        .buttonStyle(.secondary(.form))
                        .disabled(pdf == nil)
                }
                Text(store.aiLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// The figure on a page, as on paper (light), under its title and the model's caption.
    private func makePDF() -> URL? {
        guard let figure = store.figure else { return nil }
        let renderer = ImageRenderer(
            content: FigureView(spec: figure.figure).frame(width: PDFMaker.contentWidth)
                .environment(\.colorScheme, .light)
        )
        renderer.scale = PDFMaker.imageScale
        guard let image = renderer.uiImage else { return nil }
        let sheet = PDFSheet(
            title: "\(store.title) · \(store.eyebrow)", instructions: nil, blocks: [
                .image(image),
                .text(figure.caption),
            ]
        )
        return try? PDFMaker.pdf(for: sheet)
    }
}

/// Show large: the figure alone on the ground, as wide as the screen, Done to close.
private struct LargeFigure: View {
    let store: FigureStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Tokens.sectionGap) {
            HStack {
                Spacer()
                Button("Done") { dismiss() }.buttonStyle(.quiet(emphasised: true))
            }
            Spacer()
            if let figure = store.figure {
                FigureView(spec: figure.figure)
                Text(figure.caption).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
    }
}
