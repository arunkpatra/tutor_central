import Data
import DesignSystem
import Foundation

/// The server's PDF of a made sheet, mock or brief (`pdfs/<centre>/<artefact>.pdf`, `-key.pdf` with the answers; plan
/// decision 3): Share takes it when it can be had, else the phone draws its own (not made yet, offline, a tutor's own
/// sheet).
public struct ServerPDF: Sendable {
    let files: ServerFiles
    let centre: UUID

    public init(files: ServerFiles, centre: UUID) {
        self.files = files
        self.centre = centre
    }

    /// The file, named by the title as the phone's own PDF is; nil when it cannot be had.
    public func file(_ artefact: UUID, key: Bool, title: String) async -> URL? {
        let id = centre.uuidString.lowercased()
        let path = "\(id)/\(artefact.uuidString.lowercased())\(key ? "-key" : "").pdf"
        return try? await files.file(bucket: "pdfs", path: path, named: PDFMaker.fileName(title))
    }
}
