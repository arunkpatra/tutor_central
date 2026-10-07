import Testing
@testable import Domain

/// Review Focus 5: a number typed with spaces, a leading 0 or a +91 normalises to E.164, or is refused.
struct PhoneNumberTests {
    @Test func tenIndianDigitsInAnyDressBecomeE164() {
        let typings = [
            "9611299988", "96112 99988", "096112 99988", "+91 96112 99988", "+919611299988", "0091 9611299988",
            "96-112-99988", "919611299988",
        ]
        for typed in typings {
            #expect(PhoneNumber(indianDigits: typed)?.e164 == "+919611299988", "\(typed)")
        }
    }

    @Test func anythingElseIsRefused() {
        for typed in ["", "961129998", "96112999881", "1234567890", "abc", "+44 7700 900123"] {
            #expect(PhoneNumber(indianDigits: typed) == nil, "\(typed)")
        }
    }

    @Test func displayAndNationalDigits() throws {
        let number = try #require(PhoneNumber(e164: "+919611299988"))
        #expect(number.display == "+91 96112 99988" && number.nationalDigits == "9611299988")
        #expect(PhoneNumber(e164: "+1415") == nil)
    }
}
