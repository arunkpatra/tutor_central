import Domain
import Foundation
import Testing
@testable import Data

@MainActor struct FakeCentreRepositoryTests {
    @Test func noWorkspaceUntilCreatedThenTheDraftBecomesTheWorkspace() async throws {
        let fake = FakeCentreRepository()
        let user = FakeAuthRepository.meera
        #expect(try await fake.workspace(for: user) == nil)
        let draft = CentreDraft(
            displayName: "Meera Nair",
            centreName: "Bright Minds Tuition",
            whatsappNumber: "+919611299988"
        )
        let workspace = try await fake.createCentre(draft, for: user)
        #expect(workspace.centre.name == "Bright Minds Tuition")
        #expect(workspace.profile.displayName == "Meera Nair")
        #expect(workspace.centre.whatsappNumber == "+919611299988")
        #expect(try await fake.workspace(for: user) == workspace)
        try await fake.updateProfile(displayName: "Meera")
        #expect(try await fake.workspace(for: user)?.profile.displayName == "Meera")
        #expect(fake.created == [draft])
    }

    @Test func aScriptedErrorFiresOnce() async {
        let fake = FakeCentreRepository()
        fake.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) { try await fake.updateProfile(displayName: "x") }
        await #expect(throws: Never.self) { try await fake.updateProfile(displayName: "x") }
    }
}
