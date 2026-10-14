import DesignSystem
import Domain
import SwiftUI
import UIKit

/// The result's footer (components.md, Result footer): the AI line, Create again (quiet), then Copy and Share as PDF
/// (secondary 46). While creating again: the line "A new paper is on its way. This one stays until it arrives." and the
/// buttons disabled. The PDF is had when the screen shows the result: the server's file, else the phone's
/// (`ResultPDF`), the server's taken once it is made while the screen is up.
struct ResultFooter: View {
    let store: AIStore
    let generation: Generation
    let regenerating: Bool
    /// The board's done state of Copy (U33-Result-Copied).
    let copied: Bool
    let onMessage: (String) -> Void
    /// The PDF had, by the result it was had for; and the result whose try has ended.
    @State private var pdf: (generation: UUID, url: URL)?
    @State private var tried: UUID?

    var body: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(AIWords.resultLine)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if regenerating {
                    Text("A new \(noun) is on its way. This one stays until it arrives.")
                        .typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                } else {
                    Button("Create again") { _ = store.createAgain(generation) }
                        .buttonStyle(.quiet(emphasised: true))
                        .disabled(generation.request == nil)
                }
                AdaptiveRow(spacing: Tokens.tileGap, stackedSpacing: Tokens.tileGap) {
                    CopyButton(copied: copied, text: { PaperText.plain(generation.result, key: generation.printsKey) })
                    share
                }
                .disabled(regenerating)
            }
        }
        .task(id: generation.id) {
            let title = generation.title(studentName: store.studentName)
            let id = generation.id
            let first = await ResultPDF.chosen(for: generation, title: title, server: store.serverPDF)
            pdf = first.file.map { (id, $0) }
            tried = id
            // The phone's drawing stands in until the server's file is made (a result shown before its job ran).
            if !first.fromServer,
               let later = await ResultPDF.serverLater(for: generation, title: title, server: store.serverPDF) {
                pdf = (id, later)
            }
        }
    }

    @ViewBuilder private var share: some View {
        switch ResultPDF.share(file: pdf, tried: tried, for: generation.id) {
        case let .ready(url):
            ShareLink(item: url) {
                Label("Share as PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.secondary(.form))
        case .preparing:
            // This result's PDF is being had (a moment; the server's file waits up to five seconds).
            Button {} label: {
                Label("Share as PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.secondary(.form))
            .disabled(true)
        case .failed:
            Button {
                onMessage("Couldn't make the PDF. Copy the text instead.")
            } label: {
                Label("Share as PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.secondary(.form))
        }
    }

    private var noun: String {
        switch generation.kind {
        case .paper: "paper"
        case .homework: "homework"
        case .worksheet: "worksheet"
        case .progressNote: "note"
        }
    }
}
