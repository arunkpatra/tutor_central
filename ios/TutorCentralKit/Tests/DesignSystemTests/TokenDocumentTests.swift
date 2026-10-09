import Foundation
import Testing
@testable import DesignSystem

/// Reads docs/design/design-tokens.md and holds the Swift tokens to it, both ways (D25). The simulator reads the
/// host's files, so the test finds the document from its own path.
struct TokenDocumentTests {
    static let document: String = {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "ios" {
            url.deleteLastPathComponent()
        }
        url.deleteLastPathComponent()
        let path = url.appending(path: "docs/design/design-tokens.md")
        return try! String(contentsOf: path, encoding: .utf8) // swiftlint:disable:this force_try
    }()

    /// Every "| `token` | a | b | ... |" row under a "## Heading", as cells without the back-ticks; the first cell is
    /// the token's name alone.
    static func rows(under heading: String) -> [[String]] {
        guard let start = document.range(of: "\n## \(heading)") else { return [] }
        let rest = document[start.upperBound...]
        let section = rest.range(of: "\n## ").map { rest[..<$0.lowerBound] } ?? rest
        return section.split(separator: "\n").compactMap { line in
            guard line.hasPrefix("| `") else { return nil }
            var cells = line.dropFirst().dropLast().split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "`", with: "") }
            // "shadowButton (secondary)" names shadowButton.
            cells[0] = String(cells[0].split(separator: " ").first ?? "")
            return cells
        }
    }

    /// The numbers in a cell, in order: "14 × 16" → [14, 16], "160 ms" → [160].
    static func numbers(in cell: String) -> [Double] {
        cell.split(whereSeparator: { !"0123456789.".contains($0) }).compactMap { Double($0) }
    }

    @Test func everyColourInTheDocumentIsInSwiftWithTheSameValuesBothWays() {
        var documented: [String: (String, String)] = [:]
        for row in Self.rows(under: "Colour") where row.count >= 3 {
            documented[row[0]] = (row[1], row[2])
        }
        #expect(documented.count >= 26)
        for (name, (dark, light)) in documented {
            // appleButton and homeIndicator are boards' notes, not colours a view uses.
            guard let darkValue = RGBA(css: dark), let lightValue = RGBA(css: light) else { continue }
            guard case let .color(token)? = Tokens.registry[name] else {
                Issue.record("\(name) is in the document, not in Swift")
                continue
            }
            #expect(
                token.dark == darkValue && token.light == lightValue,
                "\(name) differs: Swift \(token.dark.css)/\(token.light.css), document \(dark)/\(light)"
            )
        }
        for token in Tokens.colors where documented[token.name] == nil {
            Issue.record("\(token.name) is in Swift, not in the document")
        }
    }

    @Test func everyTypeStyleMatches() {
        let extras: Set = ["displayHero", "buttonSecondary"] // named inside the display and button rows
        var documented: Set<String> = []
        for row in Self.rows(under: "Type") where row.count >= 5 {
            let name = row[0]
            documented.insert(name)
            guard case let .type(token)? = Tokens.registry[name] else {
                Issue.record("\(name) is in the document, not in Swift")
                continue
            }
            let sizeLine = Self.numbers(in: row[2])
            let weight = Self.numbers(in: row[3]).first ?? -1
            let tracking = Self.tracking(row[4])
            #expect(sizeLine.count >= 2 && token.size == sizeLine[0] && token.line == sizeLine[1], "\(name) size/line")
            #expect(Double(token.weightNumber) == weight, "\(name) weight")
            #expect(abs(Double(token.trackingEm) - tracking) < 0.0001, "\(name) tracking")
            #expect(token.uppercase == row[4].contains("uppercase"), "\(name) case")
        }
        for token in Tokens.types where !documented.contains(token.name) && !extras.contains(token.name) {
            Issue.record("\(token.name) is in Swift, not in the document")
        }
    }

    /// "-0.02em" → -0.02, "+0.08em, uppercase" → 0.08, "0" → 0.
    static func tracking(_ cell: String) -> Double {
        let value = cell.split(separator: "em").first.map(String.init) ?? "0"
        return Double(value.replacingOccurrences(of: "+", with: "").trimmingCharacters(in: .init(charactersIn: " ,")))
            ?? 0
    }

    @Test func everySpacingRadiusAndDurationMatches() {
        check("Spacing", Tokens.spacings.map { ($0.0, Double($0.1)) })
        check("Radius", Tokens.radii.map { ($0.0, Double($0.1)) })
        // The document writes milliseconds, and seconds for the toasts.
        check("Motion", Tokens.durations.map { ($0.0, $0.0.hasPrefix("toast") ? $0.1 : $0.1 * 1000) })
    }

    private func check(_ heading: String, _ swift: [(String, Double)]) {
        let splits: [String: [String]] = [
            "rowPadding": ["rowPaddingVertical", "rowPaddingHorizontal"],
            "tabBarInset": ["tabBarInsetSide", "tabBarInsetBottom"],
            "cardPadding": ["cardPadding", "cardPaddingCompact"],
            "radiusSegment": ["radiusSegment", "radiusSegmentTrack"],
            "radiusBar": ["radiusBar", "radiusBarItem"],
            "toastStay": ["toastStay", "toastStayUndo"],
        ]
        var documented: Set<String> = []
        for row in Self.rows(under: heading) where row.count >= 2 {
            let names = splits[row[0]] ?? [row[0]]
            // The second value of a split row may sit in the use column ("14 inside a compact card").
            let numbers = Self.numbers(in: row[1]) + (row.count > 2 ? Self.numbers(in: row[2]) : [])
            for (i, name) in names.enumerated() {
                documented.insert(name)
                guard let value = swift.first(where: { $0.0 == name })?.1 else {
                    Issue.record("\(name) is in the document, not in Swift")
                    continue
                }
                if name == "radiusAvatar" {
                    continue
                } // "half the size": a function
                #expect(
                    i < numbers.count && abs(value - numbers[i]) < 0.0001,
                    "\(name): Swift \(value), document \(row[1])"
                )
            }
        }
        for (name, _) in swift where !documented.contains(name) {
            Issue.record("\(name) is in Swift, not in the document")
        }
    }

    @Test func everyElevationTokenExistsWithTheDocumentsStrings() {
        var documented: Set<String> = []
        for row in Self.rows(under: "Elevation") where row.count >= 3 {
            documented.insert(row[0])
            guard case let .shadow(token)? = Tokens.registry[row[0]] else {
                Issue.record("\(row[0]) is in the document, not in Swift")
                continue
            }
            #expect(token.dark == row[1], "\(row[0]) dark")
            #expect(
                token.light == row[2].replacingOccurrences(of: "none; line border only", with: "none"),
                "\(row[0]) light"
            )
        }
        for token in Tokens.shadows where !documented.contains(token.name) {
            Issue.record("\(token.name) is in Swift, not in the document")
        }
        let raised = ShadowToken.parse(Tokens.shadowRaised.dark)
        #expect(raised.drops.count == 2 && raised.inset != nil)
        #expect(ShadowToken.parse(Tokens.shadowWell.light).drops.isEmpty)
    }
}
