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
}
