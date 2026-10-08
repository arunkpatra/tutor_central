import Testing
@testable import Domain

struct NameInitialsTests {
    @Test func twoLettersFromTheFirstTwoWords() {
        #expect(NameInitials.of("Akshita Rao") == "AR" && NameInitials.of("Bir Bikram Singh") == "BB")
        #expect(NameInitials.of("Dev") == "D" && NameInitials.of("  meera   nair ") == "MN" && NameInitials
            .of("") == "?")
    }
}
