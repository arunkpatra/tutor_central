import Foundation
import Testing
@testable import Domain

struct ArtefactContentTests {
    @Test func aSheetDecodesFromTheApisKeys() throws {
        let json = #"""
        {"title":"Balancing equations","instructions":null,
         "questions":[{"number":1,"text":"Balance H2 + O2 → H2O","answer":"2H2 + O2 → 2H2O"}],
         "for_homework":true,"light":false}
        """#
        let content = try ArtefactContent.decode(kind: .sheet, json: Data(json.utf8))
        guard case let .sheet(sheet) = content else { Issue.record("not a sheet"); return }
        #expect(sheet.forHomework)
        #expect(sheet.questions.count == 1)
        #expect(sheet.instructions == nil)
    }

    @Test func aBriefCarriesItsWorkedExampleAndThreeLines() throws {
        let json = #"""
        {"about":"A",
         "mistakes":[{"title":"T","how_to_catch":"H"},{"title":"T2","how_to_catch":"H"},
                     {"title":"T3","how_to_catch":"H"}],
         "worked_example":{"problem":"P","steps":[{"title":"S","working":"W"},{"title":"S2","working":"W"}],
                           "slip":"A common slip here: x"},
         "words":["a","b","c"]}
        """#
        guard case let .brief(brief) = try ArtefactContent.decode(kind: .brief, json: Data(json.utf8))
        else { Issue.record("not a brief"); return }
        #expect(brief.mistakes[0].howToCatch == "H")
        #expect(brief.workedExample.steps.count == 2)
        #expect(brief.words.count == 3)
    }

    @Test func aFigureDecodesByItsKind() throws {
        let json = #"""
        {"figure":{"kind":"fraction_bar","parts":4,"shaded":3,"label":"3/4"},"caption":"Three of four equal parts."}
        """#
        guard case let .figure(figure) = try ArtefactContent.decode(kind: .figure, json: Data(json.utf8))
        else { Issue.record("not a figure"); return }
        #expect(figure.figure == .fractionBar(parts: 4, shaded: 3, label: "3/4"))
    }

    @Test func anUnknownKindOrAnUnfitContentReadsAsOther() throws {
        #expect(try ArtefactContent.decode(kind: .mock, json: Data("{}".utf8)) == .other)
        #expect(try ArtefactContent.decode(kind: .sheet, json: Data(#"{"title":1}"#.utf8)) == .other)
    }

    @Test func aContentEncodesWithSnakeCaseKeys() throws {
        let sheet = SheetContent(title: "T", instructions: nil, questions: [], forHomework: true, light: true)
        let data = try ArtefactContent.sheet(sheet).encoded()
        let text = String(bytes: data, encoding: .utf8) ?? ""
        #expect(text.contains("\"for_homework\":true"))
        #expect(!text.contains("forHomework"))
    }

    @Test func theCountLineNamesQuestionsAndSteps() {
        #expect(Artefact.countLine(for: .sheet(SheetContent(
            title: "T",
            instructions: nil,
            questions: Array(repeating: SheetQuestion(number: 1, text: "q", answer: "a"), count: 8),
            forHomework: false,
            light: false
        ))) == "8 questions")
        #expect(Artefact.countLine(for: .workedExample(WorkedExample(
            problem: "p",
            steps: [.init(title: "a", working: "w"), .init(title: "b", working: "w")],
            slip: "s"
        ))) == "2 steps")
        #expect(Artefact.countLine(for: .other) == nil)
    }
}
