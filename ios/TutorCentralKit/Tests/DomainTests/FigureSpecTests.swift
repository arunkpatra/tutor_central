import Foundation
import Testing
@testable import Domain

struct FigureSpecTests {
    @Test func aFractionBarMustSumToTheWhole() {
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 3, label: "3/4").validate() == nil)
        #expect(FigureSpec.fractionBar(parts: 4, shaded: 5, label: "5/4").validate() == .shadedBeyondParts)
        #expect(FigureSpec.fractionBar(parts: 0, shaded: 0, label: "").validate() == .noParts)
    }

    @Test func aNumberLineNeedsMarksInsideItsRange() {
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, marks: [4, 8]).validate() == nil)
        #expect(FigureSpec.numberLine(from: 0, to: 10, step: 2, marks: [12]).validate() == .markOutOfRange)
        #expect(FigureSpec.numberLine(from: 5, to: 5, step: 1, marks: []).validate() == .emptyRange)
        #expect(FigureSpec.numberLine(from: 0, to: 100, step: 1, marks: []).validate() == .badStep)
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
}
