import Testing
@testable import DesignSystem

struct DialogTests {
    @Test func theTypedNameConfirmsIgnoringCaseAndSpaces() {
        #expect(DialogView.confirms(typed: "akshita ", name: "Akshita"))
        #expect(DialogView.confirms(typed: "BIR", name: "Bir"))
        #expect(!DialogView.confirms(typed: "Aksh", name: "Akshita") && !DialogView.confirms(
            typed: "",
            name: "Akshita"
        ))
    }
}
