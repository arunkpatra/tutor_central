import Foundation
import Testing
@testable import Domain

struct FigureSpecTests {
    @Test func aFractionBarMustSumToTheWhole() {
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 3, label: "3/4").validate() == nil)
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 5, label: "5/4").validate() == .shadedBeyondParts)
        #expect(FigureSpec.fractionBar(parts: 0, shaded: 0, label: "").validate() == .noParts)
    }

    @Test func aNumberLineStartsAndLandsInsideItsRange() {
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, start: 4, jumps: [2, 2]).validate() == nil)
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, start: 12, jumps: [1]).validate() == .markOutOfRange)
        #expect(FigureSpec.numberLine(from: 5, to: 5, step: 1, start: 5, jumps: [1]).validate() == .emptyRange)
        #expect(FigureSpec.numberLine(from: 0, to: 100, step: 1, start: 0, jumps: [1]).validate() == .badStep)
    }

    @Test func aTriangleNeedsAnglesThatAddTo180() {
        #expect(FigureSpec.triangle(angles: [60, 60, 60], labels: ["A", "B", "C"]).validate() == nil)
        #expect(FigureSpec.triangle(angles: [90, 60, 60], labels: ["A", "B", "C"]).validate() == .anglesDoNotSum)
        #expect(FigureSpec.triangle(angles: [90, 90], labels: ["A", "B", "C"]).validate() == .anglesDoNotSum)
    }

    @Test func placeValueAndTheUnitCircleStayInRange() {
        #expect(FigureSpec.placeValue(number: 4725).validate() == nil)
        #expect(FigureSpec.placeValue(number: 10_000_000).validate() == .numberTooLarge)
        #expect(FigureSpec.unitCircle(angleDegrees: 30).validate() == nil)
        #expect(FigureSpec.unitCircle(angleDegrees: 400).validate() == .angleOutOfRange)
    }

    @Test func aLabelledCellNeedsAtLeastOneLabelAndAFoodChainTwoLinks() {
        #expect(FigureSpec.labelledCell(kind: .plant, labels: ["Cell wall", "Nucleus"]).validate() == nil)
        #expect(FigureSpec.labelledCell(kind: .animal, labels: []).validate() == .noLabels)
        #expect(FigureSpec.foodChain(links: ["Grass"]).validate() == .tooFewLinks)
    }

    @Test func specsRoundTripAsJSON() throws {
        let spec = FigureSpec.foodChain(links: ["Grass", "Deer", "Tiger"])
        let data = try JSONEncoder().encode(spec)
        #expect(try JSONDecoder().decode(FigureSpec.self, from: data) == spec)
    }

    @Test func eachSpecNamesTheAPIsFigureKind() {
        #expect(FigureSpec.Kind.allCases.map(\.rawValue) == [
            "number_line", "fraction_bar", "place_value", "unit_circle", "triangle", "labelled_cell", "food_chain",
        ])
        #expect(FigureSpec.fractionBar(parts: 2, shaded: 1, label: "1/2").kind == .fractionBar)
        #expect(FigureSpec.foodChain(links: ["Grass", "Deer"]).kind == .foodChain)
    }

    @Test func theWireFormatRoundTrips() throws {
        let line = FigureSpec.numberLine(from: 0, to: 20, step: 2, start: 4, jumps: [6, 6])
        let data = try JSONEncoder().encode(line)
        #expect(String(bytes: data, encoding: .utf8)?.contains("\"kind\":\"number_line\"") == true)
        #expect(try JSONDecoder().decode(FigureSpec.self, from: data) == line)
        let cell = try JSONDecoder().decode(
            FigureSpec.self,
            from: Data(#"{"kind":"labelled_cell","cell":"plant","labels":["Cell wall","Nucleus"]}"#.utf8)
        )
        #expect(cell == .labelledCell(kind: .plant, labels: ["Cell wall", "Nucleus"]))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(FigureSpec.self, from: Data(#"{"kind":"pie_chart"}"#.utf8))
        }
    }

    @Test func aLandingOutsideTheLineIsRefused() {
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 8, jumps: [5]).validate() == .landingOffTheLine)
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 2, jumps: [3, 3]).validate() == nil)
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 2, jumps: [0]).validate() == .badStep)
    }

    @Test func aCellHasAtMostFiveLabelsAndAChainTwoToSixLinks() {
        #expect(FigureSpec.labelledCell(kind: .animal, labels: ["a", "b", "c", "d", "e", "f"])
            .validate() == .tooManyLabels)
        #expect(FigureSpec.foodChain(links: ["Grass"]).validate() == .tooFewLinks)
        #expect(FigureSpec.foodChain(links: Array(repeating: "x", count: 7)).validate() == .tooManyLinks)
    }

    @Test func aSkillNamesItsTemplateOrNone() {
        #expect(FigureSpec.Kind.matching(skill: "Compare simple fractions") == .fractionBar)
        #expect(FigureSpec.Kind.matching(skill: "Count on a number line") == .numberLine)
        #expect(FigureSpec.Kind.matching(skill: "Read large numbers") == .placeValue)
        #expect(FigureSpec.Kind.matching(skill: "Find the sine of an angle") == .unitCircle)
        #expect(FigureSpec.Kind.matching(skill: "Use Pythagoras' theorem") == .triangle)
        #expect(FigureSpec.Kind.matching(skill: "Label the parts of a plant cell") == .labelledCell)
        #expect(FigureSpec.Kind.matching(skill: "Explain a food chain") == .foodChain)
        #expect(FigureSpec.Kind.matching(skill: "Balance a chemical equation") == nil)
    }
}
