import Domain
import Testing

/// The app posts the kinds the contract lists (api/src/contract.ts `eventKinds`), no more (D82).
@Test func everyActivityKindIsOneTheContractLists() {
    #expect(ActivityKind.allCases.map(\.rawValue) == APIContract.eventKinds)
}
