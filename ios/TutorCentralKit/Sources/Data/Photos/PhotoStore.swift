import Foundation
import Supabase

/// The `photos` bucket (migration 0011): a JPEG under the centre, add-only; the first stored photo of V2 is a tutor's
/// own sheet (plan/phase-12-plan.md decision 13). Storage's policies keep each path inside the member's centre.
public protocol PhotoStore: Sendable {
    /// Uploads `data` to `photos/<centre>/<kind>/<uuid>.jpg`; the path inside the bucket.
    func add(_ data: Data, centre: UUID, kind: String) async throws -> String
    /// A short-lived URL the screen loads the photo from (ten minutes).
    func url(for path: String) async throws -> URL
    /// All the centre's photos removed (account deletion, D40).
    func removeAll(centre: UUID) async throws
}

public final class SupabasePhotoStore: PhotoStore {
    private let client: SupabaseClient
    /// The folders V2 writes under a centre: the tutor's own sheets, textbook pages, school items and marks.
    static let folders = ["own", "textbook", "item", "mark"]
    static let bucket = "photos"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func add(_ data: Data, centre: UUID, kind: String) async throws -> String {
        let path = Self.path(centre: centre, kind: kind)
        _ = try await client.storage.from(Self.bucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        return path
    }

    public func url(for path: String) async throws -> URL {
        try await client.storage.from(Self.bucket).createSignedURL(path: path, expiresIn: 600, download: nil as String?)
    }

    /// Folder by folder, a page at a time, until each is empty.
    public func removeAll(centre: UUID) async throws {
        let files = client.storage.from(Self.bucket)
        for folder in Self.folders {
            let prefix = "\(centre.uuidString.lowercased())/\(folder)"
            while true {
                let listed = try await files.list(path: prefix)
                let names = listed.map { "\(prefix)/\($0.name)" }
                guard !names.isEmpty else { break }
                _ = try await files.remove(paths: names)
            }
        }
    }

    static func path(centre: UUID, kind: String) -> String {
        "\(centre.uuidString.lowercased())/\(kind)/\(UUID().uuidString.lowercased()).jpg"
    }
}

/// The in-memory bucket for tests, previews and `bun shots`: the paths added, a scripted failure.
@MainActor public final class FakePhotoStore: PhotoStore {
    public private(set) var paths: [String] = []
    /// The size of the last photo added.
    public private(set) var lastBytes = 0
    /// Photos by path, for the board states (the tutor's own sheet).
    public var images: [String: Data] = [:]
    public var failure: (any Error)?

    public init(paths: [String] = []) {
        self.paths = paths
    }

    public func add(_ data: Data, centre: UUID, kind: String) async throws -> String {
        try fail()
        let path = SupabasePhotoStore.path(centre: centre, kind: kind)
        paths.append(path)
        lastBytes = data.count
        images[path] = data
        return path
    }

    /// The photo written to a temporary file, as a signed URL would serve it.
    public func url(for path: String) async throws -> URL {
        try fail()
        let url = FileManager.default.temporaryDirectory.appending(path: path.replacingOccurrences(of: "/", with: "-"))
        try (images[path] ?? Data()).write(to: url)
        return url
    }

    public func removeAll(centre: UUID) async throws {
        try fail()
        paths.removeAll { $0.hasPrefix(centre.uuidString.lowercased() + "/") }
    }

    private func fail() throws {
        if let failure {
            throw failure
        }
    }
}
