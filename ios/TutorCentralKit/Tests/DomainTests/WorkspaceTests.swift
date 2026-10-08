import Foundation
import Testing
@testable import Domain

/// Review, Important 2: a screen's change lands on the session's current workspace with only the fields that screen
/// owns, so Settings' older copy cannot put back a UPI id Parent payments has replaced.
struct WorkspaceTests {
    static let current = Workspace(
        user: AuthUser(id: UUID(), email: "meera@example.com"),
        centre: Centre(
            id: UUID(), name: "Bright Minds Tuition", whatsappNumber: "+919611299988",
            payments: PaymentSettings(upiID: "meera@ybl", paymentLink: "https://pay.example/meera", sendReceipts: false)
        ),
        profile: Profile(displayName: "Meera Nair")
    )

    @Test func settingsTakesItsFieldsAndKeepsThePayments() {
        var stale = Self.current
        stale.centre.payments = PaymentSettings(upiID: "meera@okhdfcbank")
        stale.centre.name = "Bright Minds"
        stale.centre.whatsappNumber = nil
        stale.profile.displayName = "Meera N"
        let merged = Self.current.takingSettings(from: stale)
        #expect(merged.centre.name == "Bright Minds" && merged.centre.whatsappNumber == nil)
        #expect(merged.profile.displayName == "Meera N")
        #expect(merged.centre.payments == Self.current.centre.payments, "Settings never writes the payments")
    }

    @Test func paymentsTakesOnlyThePayments() {
        var edited = Self.current
        edited.centre.name = "An old name"
        edited.centre.payments.upiConfirmedAt = Date()
        let merged = Self.current.takingPayments(from: edited)
        #expect(merged.centre.name == "Bright Minds Tuition" && merged.centre.payments == edited.centre.payments)
    }
}
