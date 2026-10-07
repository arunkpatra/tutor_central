import Testing
@testable import Domain

struct EmailAddressTests {
    @Test func acceptsAnOrdinaryAddressAndNormalisesCaseAndSpaces() {
        #expect(EmailAddress(" Meera.Nair@Gmail.com ")?.string == "meera.nair@gmail.com")
    }

    @Test func refusesWhatIsNotAnAddress() {
        for text in ["", "meera", "meera@", "@gmail.com", "meera@gmail", "me era@gmail.com", "meera@@gmail.com"] {
            #expect(EmailAddress(text) == nil, "\(text)")
        }
    }
}
