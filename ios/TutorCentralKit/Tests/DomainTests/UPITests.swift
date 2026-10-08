import Foundation
import Testing
@testable import Domain

struct UPITests {
    @Test func typedIDsAreNormalisedAndRefusedInWords() {
        #expect(UPIID.normalised("  Meera@OkHdfcBank ") == "meera@okhdfcbank")
        #expect(UPIID.normalised("9611299988@ybl") == "9611299988@ybl" && UPIID
            .normalised("a.b-c_d@upi") == "a.b-c_d@upi")
        #expect(UPIID.normalised("meera") == nil && UPIID.normalised("m@bank") == nil)
        #expect(UPIID.normalised("meera@1bank") == nil && UPIID.normalised("meera okhdfc@bank") == nil)
        #expect(UPIID.normalised("") == nil && UPIID.normalised("a@b@cd") == nil)
        #expect(UPIID.invalidMessage == "A UPI id looks like name@bank.")
    }

    @Test func aQRPayloadGivesItsPayeeOrNothing() {
        #expect(UPIQR.upiID(in: "upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair&cu=INR") == "meera@okhdfcbank")
        #expect(
            UPIQR.upiID(in: "UPI://PAY?pn=Meera&pa=Meera@OkHdfcBank") == "meera@okhdfcbank",
            "scheme and host any case; the id normalised"
        )
        #expect(UPIQR.upiID(in: "https://example.com/pay?pa=meera@okhdfcbank") == nil, "not a UPI scheme")
        #expect(UPIQR.upiID(in: "upi://pay?pn=Meera") == nil && UPIQR.upiID(in: "upi://pay?pa=not-an-id") == nil)
        #expect(UPIQR.upiID(in: "hello") == nil && UPIQR.notUPIMessage == "That QR is not a UPI QR.")
    }
}
