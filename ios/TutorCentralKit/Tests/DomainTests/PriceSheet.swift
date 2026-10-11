import Foundation
@testable import Domain

/// The price sheet the budget is tested against (plan decision 6): the models and their prices are api/models.json's
/// (D67), read from the source tree as TokenDocumentTests reads the tokens' document; the typical tokens per kind are
/// as the cost runs measured them (session 026, the twelve-student Evening batch: 13 calls, ₹4.57; the mock from
/// session 028's, ₹3.94 on Sonnet); the figure, not asked in either run, keeps its estimate.
struct PriceSheet: Decodable {
    typealias Price = ModelPrice

    let rupeesPerDollar: Double
    let models: [String: Price]
    let work: [String: String]

    static func load() throws -> PriceSheet {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "ios" {
            url.deleteLastPathComponent()
        }
        url.deleteLastPathComponent()
        return try JSONDecoder().decode(PriceSheet.self, from: Data(contentsOf: url.appending(path: "api/models.json")))
    }

    /// The API's work type for a request: the kind, a sheet by its class band.
    static func workType(_ request: ArtefactRequest) -> String {
        switch request {
        case .checks, .personalChecks: "check"
        case .placement: "placement"
        case let .sheet(_, _, level, _, _, _): level <= .five ? "sheet_to_5" : "sheet_from_6"
        case .workedExample: "worked_example"
        case .figure: "figure"
        case .brief: "brief"
        case .mock: "mock"
        }
    }

    func model(for request: ArtefactRequest) -> String? {
        work[Self.workType(request)]
    }

    func price(_ model: String) -> Price? {
        models[model]
    }

    struct Typical { let tokensIn: Int; let tokensOut: Int }
    static func typical(_ request: ArtefactRequest) -> Typical {
        switch request {
        case .checks, .personalChecks, .placement: Typical(tokensIn: 762, tokensOut: 746)
        case .sheet: Typical(tokensIn: 710, tokensOut: 876)
        case .workedExample: Typical(tokensIn: 756, tokensOut: 400)
        case .figure: Typical(tokensIn: 700, tokensOut: 200)
        case .brief: Typical(tokensIn: 1205, tokensOut: 1231)
        case .mock: Typical(tokensIn: 1166, tokensOut: 4399)
        }
    }

    static func rupees(_ requests: [ArtefactRequest]) throws -> Double {
        let sheet = try load()
        return requests.reduce(0) { sum, request in
            let tokens = typical(request)
            guard let model = sheet.model(for: request), let price = sheet.price(model) else { return .infinity }
            let dollars = (Double(tokens.tokensIn) * price.input + Double(tokens.tokensOut) * price.output) / 1_000_000
            return sum + dollars * sheet.rupeesPerDollar
        }
    }
}

/// A model's price in USD per million tokens, as api/models.json writes it.
struct ModelPrice: Decodable {
    let input: Double
    let output: Double

    enum CodingKeys: String, CodingKey {
        case input = "inputUsdPerMillion", output = "outputUsdPerMillion"
    }
}
