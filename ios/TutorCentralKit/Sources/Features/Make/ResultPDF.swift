import Data
import DesignSystem
import Domain
import Foundation

/// A V1 result's PDF for Share (Phase 21 decision 9): a paper's, homework's or worksheet's is the server's file when it
/// can be had within the short wait (D93), else the phone draws its own; a note's is always drawn on the phone.
@MainActor enum ResultPDF {
    static func file(for generation: Generation, title: String, server: ServerPDF?) async -> URL? {
        if generation.kind != .progressNote, let server,
           let file = await server.file(forGeneration: generation.id, named: PDFMaker.fileName(title)) {
            return file
        }
        return try? PDFMaker.pdf(for: generation.result.pdfSheet(title: title, key: generation.printsKey))
    }
}
