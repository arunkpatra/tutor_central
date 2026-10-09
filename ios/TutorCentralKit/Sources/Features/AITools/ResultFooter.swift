import DesignSystem
import Domain
import SwiftUI
import UIKit

/// The result's footer (components.md, Result footer): the AI line, Create again (quiet), then Copy and Share as PDF
/// (secondary 46). While creating again: the line "A new paper is on its way. This one stays until it arrives." and the
/// buttons disabled. The PDF is made when the screen shows the result (`PDFMaker`).
struct ResultFooter: View {
    let store: AIStore
    let generation: Generation
    let regenerating: Bool
    /// The board's done state of Copy (U33-Result-Copied).
    let copied: Bool
    let onMessage: (String) -> Void
    @State private var pdf: URL?

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
                HStack(spacing: Tokens.tileGap) {
                    CopyButton(copied: copied) { PaperText.plain(generation.result, key: generation.printsKey) }
                    share
                }
                .disabled(regenerating)
            }
        }
        .task(id: generation.id) {
            pdf = try? PDFMaker.pdf(
                for: generation.result, title: generation.title(studentName: store.studentName),
                key: generation.printsKey
            )
        }
    }

    @ViewBuilder private var share: some View {
        if let pdf {
            ShareLink(item: pdf) {
                Label("Share as PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.secondary(.form))
        } else {
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
