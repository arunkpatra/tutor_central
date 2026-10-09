import Domain
import Testing

struct AccountRulesTests {
    @Test func aPasswordNeedsEightCharacters() {
        #expect(!PasswordRule.isAcceptable("short7!") && PasswordRule.isAcceptable("brightminds2026"))
        #expect(PasswordRule.isAcceptable("12345678") && !PasswordRule.isAcceptable("        "))
    }

    @Test func theTypedCentreNameMatchesLoosely() {
        #expect(DeletionConfirmation.matches(typed: "  bright minds  tuition ", centreName: "Bright Minds Tuition"))
        #expect(!DeletionConfirmation.matches(typed: "Bright Minds", centreName: "Bright Minds Tuition"))
        #expect(!DeletionConfirmation.matches(typed: "", centreName: ""))
    }

    @Test func providersHaveTheirLabels() {
        #expect(SignInProvider.apple.label == "Apple" && SignInProvider.email.label == "Email code")
        #expect(SignInProvider.google.label == "Google" && SignInProvider(rawValue: "apple") == .apple)
    }
}
