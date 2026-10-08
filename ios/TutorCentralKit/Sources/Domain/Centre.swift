import Foundation

/// A tuition centre: the tutor's own, created at onboarding.
public struct Centre: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    /// E.164 (+919611299988) or nil.
    public var whatsappNumber: String?
    public var payments: PaymentSettings

    public init(id: UUID, name: String, whatsappNumber: String?, payments: PaymentSettings = PaymentSettings()) {
        self.id = id
        self.name = name
        self.whatsappNumber = whatsappNumber
        self.payments = payments
    }
}

/// The centre's payment settings (`centres.upi_id`, `payment_link`, `send_receipts`, `upi_confirmed_at`).
public struct PaymentSettings: Hashable, Sendable {
    public var upiID: String?
    public var paymentLink: String?
    public var sendReceipts: Bool
    public var upiConfirmedAt: Date?

    public init(
        upiID: String? = nil,
        paymentLink: String? = nil,
        sendReceipts: Bool = true,
        upiConfirmedAt: Date? = nil
    ) {
        self.upiID = upiID
        self.paymentLink = paymentLink
        self.sendReceipts = sendReceipts
        self.upiConfirmedAt = upiConfirmedAt
    }

    /// The payee card on Fees: an id that was never confirmed (P5-Fees-Payee).
    public var needsConfirmation: Bool {
        upiID != nil && upiConfirmedAt == nil
    }
}
