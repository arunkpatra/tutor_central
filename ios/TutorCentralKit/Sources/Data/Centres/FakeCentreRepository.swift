import Domain
import Foundation

/// The in-memory centre for tests, previews and `bun shots`: one workspace, a scripted error, a record of every
/// write.
@MainActor public final class FakeCentreRepository: CentreRepository {
    public var workspace: Workspace?
    public var nextError: (any Error)?
    public private(set) var created: [CentreDraft] = []
    public private(set) var centreUpdates: [(name: String, whatsappNumber: String?)] = []
    public private(set) var profileUpdates: [String] = []

    public init(workspace: Workspace? = nil) {
        self.workspace = workspace
    }

    public func workspace(for _: AuthUser) async throws -> Workspace? {
        try takeError()
        return workspace
    }

    public func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace {
        try takeError()
        created.append(draft)
        let made = Workspace(
            user: user,
            centre: Centre(id: UUID(), name: draft.centreName, whatsappNumber: draft.whatsappNumber),
            profile: Profile(displayName: draft.displayName)
        )
        workspace = made
        return made
    }

    public func updateCentre(id _: UUID, name: String, whatsappNumber: String?) async throws {
        try takeError()
        centreUpdates.append((name, whatsappNumber))
        workspace?.centre.name = name
        workspace?.centre.whatsappNumber = whatsappNumber
    }

    public func updateProfile(displayName: String) async throws {
        try takeError()
        profileUpdates.append(displayName)
        workspace?.profile.displayName = displayName
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
