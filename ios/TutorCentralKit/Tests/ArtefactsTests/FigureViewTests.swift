import Domain
import Testing
@testable import Artefacts

/// The seven figures the app draws (D59): what the app checked, each template's own reading.
struct FigureViewTests {
    @Test func theCheckedCaptionsSayWhatTheAppChecked() {
        #expect(FigureView.checkedCaption(.numberLine(from: 0, to: 20, step: 2, start: 4, jumps: [6, 6]))
            == "The jumps land on 16, inside the line.")
        #expect(FigureView.checkedCaption(.fractionBar(parts: 4, shaded: 3, label: "3/4"))
            == "4 equal parts, 3 shaded: 3/4.")
        #expect(FigureView.checkedCaption(.placeValue(number: 4507)) == "4,507 read by place.")
        #expect(FigureView.checkedCaption(.unitCircle(angleDegrees: 30))
            == "30° on the unit circle: sine 0.5, cosine 0.87.")
        #expect(FigureView.checkedCaption(.triangle(angles: [90, 60, 30], labels: ["AB", "BC", "CA"]))
            == "Angles 90°, 60°, 30° add to 180°.")
        #expect(FigureView.checkedCaption(.labelledCell(kind: .plant, labels: ["a", "b", "c", "d", "e"]))
            == "5 parts named as the chapter names them.")
        #expect(FigureView.checkedCaption(.foodChain(links: ["Grass", "Grasshopper", "Frog", "Snake"]))
            == "4 links, grass first.")
    }

    @Test func theTitlesNameTheTemplates() {
        #expect(FigureView.title(.numberLine) == "Number line")
        #expect(FigureView.title(.labelledCell) == "Labelled cell")
        #expect(FigureView.title(.foodChain) == "Food chain")
    }

    @Test func thePlaceValueColumnsReadTheDigitsAndTheirWorth() {
        let columns = PlaceValueFigure.columns(4507)
        #expect(columns.map(\.place) == ["Thousands", "Hundreds", "Tens", "Ones"])
        #expect(columns.map(\.digit) == [4, 5, 0, 7])
        #expect(columns.map(\.worth) == ["4,000", "500", "0", "7"])
        #expect(PlaceValueFigure.sum(347) == "300 + 40 + 7 = 347")
        #expect(PlaceValueFigure.columns(0).map(\.place) == ["Ones"])
    }

    @Test func theUnitCircleRatiosRoundToTwoPlaces() {
        #expect(UnitCircleFigure.ratios(30) == .init(sine: "0.5", cosine: "0.87"))
        #expect(UnitCircleFigure.ratios(90) == .init(sine: "1", cosine: "0"))
        #expect(UnitCircleFigure.ratios(270) == .init(sine: "-1", cosine: "0"))
    }

    @Test func aTriangleMarksTheRightAngleOnlyWhenOneIsNinety() {
        #expect(TriangleFigure.rightAngleIndex([90, 60, 30]) == 0)
        #expect(TriangleFigure.rightAngleIndex([60, 60, 60]) == nil)
    }

    @Test func theRuleShowsOnlyWhenTheSidesKeepIt() {
        #expect(TriangleFigure.rule(angles: [90, 53, 37], labels: ["5", "4", "3"]) == ["4² + 3² = 5²", "16 + 9 = 25"])
        #expect(TriangleFigure.rule(angles: [90, 53, 37], labels: ["6", "4", "3"]) == nil)
        #expect(TriangleFigure.rule(angles: [60, 60, 60], labels: ["2", "2", "2"]) == nil)
        #expect(TriangleFigure.rule(angles: [90, 45, 45], labels: ["AC", "BC", "AB"]) == nil)
    }

    @Test func theNumberLineSumReadsTheJumps() {
        #expect(NumberLineFigure.sum(start: 3, jumps: [1, 1, 1, 1]) == "3 + 4 = 7")
        #expect(NumberLineFigure.sum(start: 9, jumps: [-2, -2]) == "9 − 4 = 5")
    }
}
