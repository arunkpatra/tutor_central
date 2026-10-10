import DesignSystem
import Domain
import SwiftUI

/// The tutor's brief (P10-Brief): the hero; What the chapter is about; Three common mistakes, each with how to catch
/// it; The worked example to use, its steps opened in a sheet; Words to say; the footer with the AI line, Make it
/// again, Copy and Share as PDF.
struct BriefView: View {
    static let aiLine = "AI can make mistakes. Read it as a colleague's note, not a textbook."

    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State private var store: BriefStore
    @State private var topInset: CGFloat = 0
    @State private var pdf: URL?
    @State private var showingExample = false

    init(store: BriefStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Brief") { dismiss() }
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
            if store.brief != nil {
                footer
            }
        }
        .sheet(isPresented: $showingExample) {
            if let example = store.brief?.workedExample {
                WorkedExampleView(store: WorkedExampleStore(example: example))
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task { await store.load() }
        .task(id: store.artefact?.id) {
            pdf = store.brief == nil ? nil : try? PDFMaker.pdf(for: store.pdfSheet)
        }
    }

    @ViewBuilder private var content: some View {
        if let failed = store.loadFailed {
            Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
        } else if let brief = store.brief {
            ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.line)
                .opacity(store.making ? Tokens.opacityStale : 1)
            BriefSection(title: "What the chapter is about") { BriefText(text: brief.about) }
            BriefSection(title: "Three common mistakes") {
                Card {
                    VStack(spacing: 0) {
                        ForEach(Array(brief.mistakes.enumerated()), id: \.offset) { index, mistake in
                            StepRow(number: index + 1, title: mistake.title, working: mistake.howToCatch, shown: true)
                                .rowDivider(index < brief.mistakes.count - 1)
                        }
                    }
                }
            }
            BriefSection(title: "The worked example to use") {
                Card {
                    ToolRow(symbol: "doc.text", title: brief.workedExample.problem, line: store.exampleLine) {
                        showingExample = true
                    }
                }
            }
            BriefSection(title: "Words to say") { BriefText(text: store.wordsLine) }
        } else {
            Card { SkeletonRow() }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(Self.aiLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if store.making {
                    HStack(spacing: Tokens.inline) {
                        RefreshSpinner()
                        Text("A new brief is on its way. This one stays until it arrives.")
                            .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    }
                } else {
                    Button("Make it again") { Task { await store.makeAgain() } }
                        .buttonStyle(.quiet(emphasised: true))
                }
                HStack(spacing: Tokens.tileGap) {
                    CopyButton { store.copyText }
                    if let pdf {
                        ShareLink(item: pdf) { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form))
                    } else {
                        Button {} label: { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form)).disabled(true)
                    }
                }
                .disabled(store.making)
            }
        }
    }
}

/// A brief's section: its headline and the card under it.
private struct BriefSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            content
        }
    }
}

/// A card of reading text (subhead, text2).
private struct BriefText: View {
    let text: String

    var body: some View {
        Card {
            Text(text).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.rowPaddingHorizontal)
        }
    }
}
