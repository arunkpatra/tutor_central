import Foundation
@testable import Domain

/// The price sheet the budget is tested against (plan decision 6): USD per million tokens, the rupee at 85, and the
/// typical tokens per kind (the cost run of Task 24 replaces these with the measured figures).
enum PriceSheet {
    static let rupeesPerDollar = 85.0
    struct Model { let input: Double; let output: Double }
    static let haiku = Model(input: 0.10, output: 0.50), sonnet = Model(input: 2, output: 10), opus = Model(
        input: 4,
        output: 20
    )
    struct Typical { let tokensIn: Int; let tokensOut: Int }
    static func typical(_ request: ArtefactRequest) -> Typical {
        switch request {
        case .checks, .personalChecks, .placement: Typical(tokensIn: 700, tokensOut: 250)
        case .sheet: Typical(tokensIn: 900, tokensOut: 1400)
        case .workedExample: Typical(tokensIn: 700, tokensOut: 700)
        case .figure: Typical(tokensIn: 700, tokensOut: 200)
        case .brief: Typical(tokensIn: 800, tokensOut: 1300)
        }
    }

    static func model(_ request: ArtefactRequest) -> Model {
        switch request {
        case .checks, .personalChecks, .placement: haiku
        case let .sheet(_, _, level, _, _, _): level <= .five ? haiku : sonnet
        case .workedExample, .figure, .brief: sonnet
        }
    }

    static func rupees(_ requests: [ArtefactRequest]) -> Double {
        requests.reduce(0) { sum, request in
            let tokens = typical(request), price = model(request)
            let dollars = (Double(tokens.tokensIn) * price.input + Double(tokens.tokensOut) * price.output) / 1_000_000
            return sum + dollars * rupeesPerDollar
        }
    }
}
