import Data
import DesignSystem
import Domain
import Foundation

/// A V1 result's PDF for Share (Phase 21 decision 9): a paper's, homework's or worksheet's is the server's file when it
/// can be had within the short wait (D93), else the phone draws its own; a note's is always drawn on the phone.
@MainActor enum ResultPDF {
    static func file(for generation: Generation, title: String, server: ServerPDF?) async -> URL? {
        await chosen(for: generation, title: title, server: server).file
    }

    /// The file and whether it is the server's.
    static func chosen(
        for generation: Generation, title: String, server: ServerPDF?
    ) async -> (file: URL?, fromServer: Bool) {
        if generation.kind != .progressNote, let server,
           let file = await server.file(forGeneration: generation.id, named: PDFMaker.fileName(title)) {
            return (file, true)
        }
        return (try? PDFMaker.pdf(for: generation.result.pdfSheet(title: title, key: generation.printsKey)), false)
    }

    /// The server's file asked again (a result shown before its PDF job ran): up to `tries` times, `every` apart; nil
    /// for a note, with no server, or when it never came.
    static func serverLater(
        for generation: Generation, title: String, server: ServerPDF?, tries: Int = 6, every: Duration = .seconds(10)
    ) async -> URL? {
        guard generation.kind != .progressNote, let server else { return nil }
        for _ in 0 ..< tries {
            try? await Task.sleep(for: every)
            if Task.isCancelled {
                return nil
            }
            if let file = await server.file(forGeneration: generation.id, named: PDFMaker.fileName(title)) {
                return file
            }
        }
        return nil
    }
}
