import Foundation
@testable import Domain

/// The price sheet the budget is tested against (plan decision 6): USD per million tokens, the rupee at 85, and the
/// typical tokens per kind as the cost run measured them (session 026, the twelve-student Evening batch: 13 calls,
/// ₹4.57); the figure, not asked in that run, keeps its estimate.
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
        case .checks, .personalChecks, .placement: Typical(tokensIn: 762, tokensOut: 746)
        case .sheet: Typical(tokensIn: 710, tokensOut: 876)
        case .workedExample: Typical(tokensIn: 756, tokensOut: 400)
        case .figure: Typical(tokensIn: 700, tokensOut: 200)
        case .brief: Typical(tokensIn: 1205, tokensOut: 1231)
        // An estimate until the cost run (plan/phase-13-plan.md Task 27).
        case .mock: Typical(tokensIn: 2000, tokensOut: 2500)
        }
    }

    static func model(_ request: ArtefactRequest) -> Model {
        switch request {
        case .checks, .personalChecks, .placement: haiku
        case let .sheet(_, _, level, _, _, _): level <= .five ? haiku : sonnet
        case .workedExample, .figure, .brief, .mock: sonnet
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
