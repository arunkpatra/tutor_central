import Testing
@testable import DesignSystem

struct PhoneWellTests {
    /// Whatever is typed or pasted (letters from a hardware keyboard included), the field shows grouped digits.
    @Test func typedTextBecomesGroupedDigits() {
        #expect(PhoneWell.typed("96112Probe Tutor") == (shown: "96112", digits: "96112"))
        #expect(PhoneWell.typed("9611299988") == (shown: "96112 99988", digits: "9611299988"))
        #expect(PhoneWell.typed("96112 99988") == (shown: "96112 99988", digits: "9611299988"))
        #expect(PhoneWell.typed("") == (shown: "", digits: ""))
    }

    /// Review minor: only 0 to 9 count (Devanagari digits and "½" pass `isNumber`).
    @Test func onlyASCIIDigitsCount() {
        #expect(PhoneWell.typed("९८७६५४३२१०").digits == "")
        #expect(PhoneWell.typed("98765½").digits == "98765")
    }

    /// Review minor: a pasted +91 or 0091 number is read, not cut at 12 digits or shown with its 91.
    @Test func aPastedNumberWithItsCountryCodeIsRead() {
        #expect(PhoneWell.typed("+91 96112 99988") == (shown: "96112 99988", digits: "9611299988"))
        #expect(PhoneWell.typed("0091 96112 99988") == (shown: "96112 99988", digits: "9611299988"))
        #expect(PhoneWell.typed("096112 99988") == (shown: "96112 99988", digits: "9611299988"))
    }
}
