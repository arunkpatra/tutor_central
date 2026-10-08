import Domain
import Foundation
import Testing
@testable import Data

/// The stack's answers on 2026-10-08: the centre with its payment columns, and a confirmation update's answer.
struct CentreRowTests {
    static let centres = Data("""
    [{"id":"22222222-2222-2222-2222-222222222222","name":"Bright Minds Tuition","whatsapp_number":"+919611299988",\
    "upi_id":"meera@okhdfcbank","upi_confirmed_at":null,"payment_link":null,"send_receipts":true}]
    """.utf8)
    static let confirmed = Data("""
    [{"upi_id":"meera@okhdfcbank","upi_confirmed_at":"2026-10-07T07:35:00+00:00","payment_link":null,\
    "send_receipts":true}]
    """.utf8)

    @Test func decodesTheCentreWithItsPayments() throws {
        let decoder = SupabaseCentreRepository.decoder
        let row = try #require(try decoder.decode([CentreRow].self, from: Self.centres).first)
        let centre = row.centre
        #expect(centre.name == "Bright Minds Tuition" && centre.whatsappNumber == "+919611299988")
        #expect(centre.payments.upiID == "meera@okhdfcbank" && centre.payments.needsConfirmation)
        #expect(centre.payments.paymentLink == nil && centre.payments.sendReceipts)
        let settings = try #require(try decoder.decode([PaymentsRow].self, from: Self.confirmed).first).settings
        #expect(!settings.needsConfirmation && settings.upiConfirmedAt != nil)
    }
}
