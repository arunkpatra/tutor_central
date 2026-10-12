import Foundation
import Synchronization
import Testing
@testable import Data

struct ServerFilesTests {
    final class Downloads: Sendable {
        let count = Mutex(0)
    }

    func folder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "files-\(UUID().uuidString)")
    }

    @Test func twoAsksDownloadOnceIntoTheCentresFolderUnderTheSharedName() async throws {
        let (centre, directory, downloads) = (UUID(), folder(), Downloads())
        let files = ServerFiles(centre: centre, directory: directory) { bucket, path in
            downloads.count.withLock { $0 += 1 }
            return Data("\(bucket)/\(path)".utf8)
        }
        let first = try await files.file(bucket: "exports", path: "c/s/j.pdf", named: "Hemanth · everything kept")
        let second = try await files.file(bucket: "exports", path: "c/s/j.pdf", named: "Hemanth · everything kept")
        #expect(downloads.count.withLock { $0 } == 1)
        #expect(first.lastPathComponent == "Hemanth · everything kept.pdf" && first != second)
        #expect(try String(contentsOf: second, encoding: .utf8) == "exports/c/s/j.pdf")
        let kept = directory.appending(path: "files-\(centre.uuidString.lowercased())/exports/c/s/j.pdf")
        #expect(FileManager.default.fileExists(atPath: kept.path))
    }

    @Test func aFileThatCannotBeHadThrowsAndKeepsNothing() async {
        let (centre, directory) = (UUID(), folder())
        let files = ServerFiles(centre: centre, directory: directory) { _, _ in
            throw URLError(.notConnectedToInternet)
        }
        await #expect(throws: URLError.self) {
            try await files.file(bucket: "pdfs", path: "c/a.pdf", named: "Sheet")
        }
        let kept = directory.appending(path: "files-\(centre.uuidString.lowercased())/pdfs/c/a.pdf")
        #expect(!FileManager.default.fileExists(atPath: kept.path))
    }

    @Test func theWipeRemovesTheCentresFiles() async throws {
        let (centre, directory) = (UUID(), folder())
        let files = ServerFiles(centre: centre, directory: directory) { _, _ in Data("x".utf8) }
        _ = try await files.file(bucket: "pdfs", path: "c/a.pdf", named: "Sheet")
        Wipe.everything(
            centre: centre, directory: directory,
            defaults: UserDefaults(suiteName: "wipe-\(UUID().uuidString)") ?? .standard
        )
        #expect(!FileManager.default
            .fileExists(atPath: directory.appending(path: "files-\(centre.uuidString.lowercased())").path))
    }
}
