import Foundation
import Testing
@testable import Domain

struct MockPatternTests {
    @Test func theDefaultFollowsTheClass() {
        for level in [ClassLevel.lkg, .ukg, .one, .five] {
            #expect(MockPattern.default(for: level).marks == 20 && MockPattern.default(for: level)
                .durationMinutes == 30)
        }
        for level in [ClassLevel.six, .seven] {
            #expect(MockPattern.default(for: level).marks == 25 && MockPattern.default(for: level)
                .durationMinutes == 40)
        }
        for level in [ClassLevel.eight, .nine] {
            #expect(MockPattern.default(for: level).marks == 40 && MockPattern.default(for: level)
                .durationMinutes == 60)
        }
        for level in [ClassLevel.ten, nil] {
            #expect(MockPattern.default(for: level).marks == 80 && MockPattern.default(for: level)
                .durationMinutes == 180)
        }
        #expect(MockPattern.default(for: .eight).sections == nil)
    }

    @Test func aBlueprintReadsAsAPattern() throws {
        let json = Data("""
        {"marks": 80, "durationMinutes": 180, "sections": [
          {"name": "A (reading)", "questions": 2, "marksEach": 10},
          {"name": "B (grammar)", "questions": 10, "marksEach": 1},
          {"name": "B (writing)", "questions": 2, "marksEach": 5},
          {"name": "C (extracts)", "questions": 2, "marksEach": 5},
          {"name": "C (short answer)", "questions": 6, "marksEach": 3},
          {"name": "C (long answer)", "questions": 2, "marksEach": 6}
        ]}
        """.utf8)
        let pattern = try #require(MockPattern.blueprint(json))
        #expect(pattern.marks == 80 && pattern.durationMinutes == 180 && pattern.sections?.count == 6)
        #expect(MockPattern.blueprint(Data("null".utf8)) == nil)
        #expect(MockPattern.blueprint(Data("{\"marks\": 0}".utf8)) == nil)
    }

    @Test func theLineReadsMarksAndMinutes() {
        #expect(MockPattern.default(for: .seven).line == "25 marks · 40 minutes")
    }
}
