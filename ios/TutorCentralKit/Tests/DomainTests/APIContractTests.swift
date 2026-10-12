import Domain
import Testing

/// The generated file compiles and carries the API's values (`bun contract`, D80).
@Test func theGeneratedContractCarriesTheAPIsLimits() {
    #expect(APIContract.tutorSaysMax == 300)
    #expect(APIContract.pagesMax == 6)
    #expect(APIContract.eventKinds.count == 5)
    #expect(MakeRules.tutorSaysLimit == APIContract.tutorSaysMax)
}
