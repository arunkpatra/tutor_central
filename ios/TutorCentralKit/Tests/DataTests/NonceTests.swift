import Testing
@testable import Data

struct NonceTests {
    @Test func aNonceIsSixtyFourHexCharactersAndNeverRepeats() {
        let first = Nonce.random()
        let second = Nonce.random()
        #expect(first.count == 64 && first.allSatisfy(\.isHexDigit) && first != second)
    }

    @Test func sha256IsTheKnownDigest() {
        #expect(Nonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
