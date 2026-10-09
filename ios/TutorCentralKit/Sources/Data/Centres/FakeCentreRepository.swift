import Domain
import Foundation

/// The in-memory centre for tests, previews and `bun shots`: one workspace, a scripted error, a record of every
/// write.
@MainActor public final class FakeCentreRepository: CentreRepository {
    /// The boards' tutor: Meera Nair of Bright Minds Tuition.
    public nonisolated static let meeraWorkspace = Workspace(
        user: FakeAuthRepository.meera,
        centre: Centre(
            id: UUID(uuid: (
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22
            )),
            name: "Bright Minds Tuition",
            whatsappNumber: "+919611299988",
            payments: PaymentSettings(
                upiID: "meera@okhdfcbank", sendReceipts: true,
                upiConfirmedAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 9))
            )
        ),
        profile: Profile(displayName: "Meera Nair")
    )

    /// Agreed to the AI notice on 1 October: the scan and check boards' centre.
    public nonisolated static let meeraWorkspaceConsented: Workspace = {
        var workspace = meeraWorkspace
        workspace.centre.aiConsentAt = DayHeading.india.date(from: DateComponents(
            year: 2026,
            month: 10,
            day: 1,
            hour: 9
        ))
        return workspace
    }()

    /// The id set and never confirmed: Fees asks "Parents are told to pay …" (P5-Fees-Payee).
    public nonisolated static let meeraWorkspaceUnconfirmed = with(payments: PaymentSettings(upiID: "meera@okhdfcbank"))

    /// No UPI id yet (P5-Fees-Empty, P5-Payments-Empty).
    public nonisolated static let meeraWorkspaceWithoutUPI = with(payments: PaymentSettings())

    public var workspace: Workspace?
    public var nextError: (any Error)?
    /// The first workspace lookup answers after this long: lets a test overlap two lookups, as a real network can.
    public var firstLookupDelay: Duration?
    public private(set) var created: [CentreDraft] = []
    public private(set) var nameUpdates: [String] = []
    public private(set) var whatsAppUpdates: [String?] = []
    public private(set) var profileUpdates: [String] = []
    public private(set) var upiUpdates: [String?] = []
    public private(set) var linkUpdates: [String?] = []
    public private(set) var receiptUpdates: [Bool] = []
    public private(set) var confirmations: [Date] = []
    public private(set) var consents: [Date] = []
    public private(set) var hasPasswordSet = 0

    public init(workspace: Workspace? = nil) {
        self.workspace = workspace
    }

    public func workspace(for _: AuthUser) async throws -> Workspace? {
        if let delay = firstLookupDelay {
            firstLookupDelay = nil
            try? await Task.sleep(for: delay)
        }
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

    public func updateCentreName(id _: UUID, name: String) async throws {
        try takeError()
        nameUpdates.append(name)
        workspace?.centre.name = name
    }

    public func updateWhatsAppNumber(id _: UUID, number: String?) async throws {
        try takeError()
        whatsAppUpdates.append(number)
        workspace?.centre.whatsappNumber = number
    }

    public func updateProfile(displayName: String) async throws {
        try takeError()
        profileUpdates.append(displayName)
        workspace?.profile.displayName = displayName
    }

    public func updateUPI(id _: UUID, upiID: String?) async throws {
        try takeError()
        upiUpdates.append(upiID)
        workspace?.centre.payments.upiID = upiID
        workspace?.centre.payments.upiConfirmedAt = nil
    }

    public func updatePaymentLink(id _: UUID, link: String?) async throws {
        try takeError()
        linkUpdates.append(link)
        workspace?.centre.payments.paymentLink = link
    }

    public func updateSendReceipts(id _: UUID, on: Bool) async throws {
        try takeError()
        receiptUpdates.append(on)
        workspace?.centre.payments.sendReceipts = on
    }

    public func confirmUPI(id _: UUID, at: Date) async throws {
        try takeError()
        confirmations.append(at)
        workspace?.centre.payments.upiConfirmedAt = at
    }

    public func recordAIConsent(id _: UUID, at: Date) async throws {
        try takeError()
        consents.append(at)
        workspace?.centre.aiConsentAt = at
    }

    public func setHasPassword() async throws {
        try takeError()
        hasPasswordSet += 1
    }

    private nonisolated static func with(payments: PaymentSettings) -> Workspace {
        var workspace = meeraWorkspace
        workspace.centre.payments = payments
        return workspace
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
