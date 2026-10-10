import Testing
@testable import Domain

struct ClassLevelTests {
    @Test func rawValuesMatchTheDatabase() {
        #expect(ClassLevel.allCases.map(\.rawValue) == [
            "lkg",
            "ukg",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
        ])
        #expect(ClassLevel(rawValue: "11") == nil)
    }

    @Test func stagesAndRules() {
        #expect(ClassLevel.lkg.stage == .preschool && ClassLevel.two.stage == .early && ClassLevel.six.stage == .middle)
        #expect(ClassLevel.ten.stage == .secondary)
        #expect(ClassLevel.seven.expectsBoard == false && ClassLevel.eight.expectsBoard == true)
        #expect(ClassLevel.five.homeworkIsLight == true && ClassLevel.six.homeworkIsLight == false)
        #expect(ClassLevel.one.usesLadder == true && ClassLevel.three.usesLadder == true && ClassLevel.four
            .usesLadder == false)
        #expect(ClassLevel.ukg.hasChapters == false && ClassLevel.one.hasChapters == true)
    }

    @Test func titlesAndOrder() {
        #expect(ClassLevel.lkg.title == "LKG" && ClassLevel.ukg.title == "UKG" && ClassLevel.ten.title == "Class 10")
        #expect(ClassLevel.ukg < ClassLevel.one && ClassLevel.nine < ClassLevel
            .ten && !(ClassLevel.ten < ClassLevel.two))
        #expect(ClassLevel.allCases.sorted() == ClassLevel.allCases)
    }

    @Test func boardsAndLanguagesMatchTheDatabaseAndTheBoards() {
        #expect(Board.allCases.map(\.rawValue) == ["cbse", "icse", "karnataka", "other"])
        #expect(Board.allCases.map(\.title) == ["CBSE", "ICSE", "Karnataka state", "Other"])
        #expect(MessageLanguage.allCases.map(\.rawValue) == ["en", "hinglish", "hi", "kn"])
        #expect(MessageLanguage.allCases.map(\.title) == ["English", "Hinglish", "Hindi", "Kannada"])
        #expect(MessageLanguage.default == .english)
    }
}
