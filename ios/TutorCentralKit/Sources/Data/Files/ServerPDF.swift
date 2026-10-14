import Foundation

/// The server's PDF of a made sheet, mock or brief (`pdfs/<centre>/<artefact>.pdf`, `-key.pdf` with the answers; plan
/// decision 3) or of a V1 result (`gen-<id>.pdf`, Phase 21 decision 9): Share takes it when it can be had, else the
/// phone
/// draws its own (not made yet, offline, a tutor's own sheet). The caller names the file as the phone's own PDF is
/// named.
public struct ServerPDF: Sendable {
    let files: ServerFiles
    let centre: UUID
    let online: @Sendable () async -> Bool
    /// How long Share waits for a download before the phone draws its own (the review's R-app-7: a stalled read takes
    /// about 20 s to fail).
    let wait: Duration

    public init(
        files: ServerFiles, centre: UUID, online: @escaping @Sendable () async -> Bool = { true },
        wait: Duration = .seconds(5)
    ) {
        self.files = files
        self.centre = centre
        self.online = online
        self.wait = wait
    }

    /// An artefact's file, the questions or (`key`) the key's form.
    public func file(_ artefact: UUID, key: Bool, named name: String) async -> URL? {
        await file(path: "\(folder)/\(artefact.uuidString.lowercased())\(key ? "-key" : "").pdf", named: name)
    }

    /// A V1 result's file, by its generation.
    public func file(forGeneration generation: UUID, named name: String) async -> URL? {
        await file(path: "\(folder)/gen-\(generation.uuidString.lowercased()).pdf", named: name)
    }

    private var folder: String {
        centre.uuidString.lowercased()
    }

    /// The copy downloaded before at once; else, online, the download if it answers within `wait`; nil otherwise.
    private func file(path: String, named name: String) async -> URL? {
        if let kept = await files.kept(bucket: "pdfs", path: path, named: name) {
            return kept
        }
        guard await online() else { return nil }
        let (files, wait) = (files, wait)
        return await withTaskGroup(of: URL?.self) { group in
            group.addTask { try? await files.file(bucket: "pdfs", path: path, named: name) }
            group.addTask {
                try? await Task.sleep(for: wait)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
