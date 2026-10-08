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

    @Test func paymentsAreWrittenOneColumnAtATime() async throws {
        let repo = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
        try await repo.updateUPI(id: repo.workspace?.centre.id ?? UUID(), upiID: "meera@ybl")
        #expect(repo.upiUpdates == ["meera@ybl"] && repo.workspace?.centre.payments.upiID == "meera@ybl")
        #expect(repo.workspace?.centre.payments.upiConfirmedAt == nil, "a changed id is unconfirmed again")
        try await repo.confirmUPI(id: UUID(), at: FakeCountsRepository.fixedNow)
        #expect(repo.workspace?.centre.payments.upiConfirmedAt == FakeCountsRepository.fixedNow)
        #expect(repo.confirmations == [FakeCountsRepository.fixedNow])
        try await repo.updatePaymentLink(id: UUID(), link: "https://pay.example/meera")
        try await repo.updateSendReceipts(id: UUID(), on: false)
        #expect(repo.linkUpdates == ["https://pay.example/meera"] && repo.receiptUpdates == [false])
        #expect(repo.workspace?.centre.payments.paymentLink == "https://pay.example/meera")
        #expect(repo.workspace?.centre.payments.sendReceipts == false)
        #expect(FakeCentreRepository.meeraWorkspace.centre.payments.upiConfirmedAt != nil)
        #expect(FakeCentreRepository.meeraWorkspaceUnconfirmed.centre.payments.needsConfirmation)
        #expect(FakeCentreRepository.meeraWorkspaceWithoutUPI.centre.payments.upiID == nil)
    }

    @Test func theConsentIsRecordedAndTheConsentedWorkspaceCarriesIt() async throws {
        let fake = FakeCentreRepository()
        let at = Date(timeIntervalSince1970: 1_791_444_900)
        try await fake.recordAIConsent(id: FakeCentreRepository.meeraWorkspace.centre.id, at: at)
        #expect(fake.consents == [at])
        let consented = try #require(FakeCentreRepository.meeraWorkspaceConsented.centre.aiConsentAt)
        #expect(Day(consented, calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 1))
        #expect(FakeCentreRepository.meeraWorkspace.centre.aiConsentAt == nil)
    }
}
