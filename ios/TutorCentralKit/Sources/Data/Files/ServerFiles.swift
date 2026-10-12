import Foundation
import Supabase

/// The files the server made for the centre (Phase 18): a sheet's, mock's or brief's PDF in `pdfs`, a student's export
/// in `exports`. Each is downloaded once into `Application Support/TutorCentral/files-<centre>/` (protected as the
/// copies are; sign-out's wipe removes the folder, D40) and handed over under the name the tutor shares it by.
public actor ServerFiles {
    public typealias Download = @Sendable (_ bucket: String, _ path: String) async throws -> Data

    private let folder: URL
    private let download: Download

    public init(centre: UUID, directory: URL? = nil, download: @escaping Download) {
        let root = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
        folder = root.appendingPathComponent("files-\(centre.uuidString.lowercased())", isDirectory: true)
        self.download = download
    }

    /// Storage through the signed-in user (the members' read rule on both buckets).
    public static func live(client: SupabaseClient, centre: UUID) -> ServerFiles {
        ServerFiles(centre: centre) { bucket, path in
            try await client.storage.from(bucket).download(path: path)
        }
    }

    /// The file at `bucket/path` when it was downloaded before, with no download: a copy named "<name>.pdf" for Share.
    public func kept(bucket: String, path: String, named name: String) -> URL? {
        let kept = keptURL(bucket: bucket, path: path)
        guard FileManager.default.fileExists(atPath: kept.path) else { return nil }
        return try? named(kept, name)
    }

    /// The file at `bucket/path`, downloaded once; a copy named "<name>.pdf" for Share. Throws when it cannot be had
    /// (not made yet, offline).
    public func file(bucket: String, path: String, named name: String) async throws -> URL {
        let kept = keptURL(bucket: bucket, path: path)
        if !FileManager.default.fileExists(atPath: kept.path) {
            let data = try await download(bucket, path)
            try FileManager.default.createDirectory(
                at: kept.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try data.write(to: kept, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
        return try named(kept, name)
    }

    private func keptURL(bucket: String, path: String) -> URL {
        folder.appendingPathComponent(bucket, isDirectory: true).appendingPathComponent(path)
    }

    private func named(_ kept: URL, _ name: String) throws -> URL {
        let shared = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: shared, withIntermediateDirectories: true)
        let named = shared.appendingPathComponent("\(name).pdf")
        try FileManager.default.copyItem(at: kept, to: named)
        return named
    }
}
