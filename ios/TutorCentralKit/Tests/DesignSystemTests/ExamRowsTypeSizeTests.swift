import Foundation
import Testing

/// The exam page's rows clipped at the largest text size (Phase 21 hand run 12: "Dev, Meher and…", the chip "Re…", a
/// word broken): the tool row's chip and the last days' trailing chips and buttons sit in an `AdaptiveRow`, which puts
/// them under the words at the accessibility sizes.
struct ExamRowsTypeSizeTests {
    static var sources: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources")
    }

    func text(_ path: String) throws -> String {
        try String(contentsOf: Self.sources.appending(path: path), encoding: .utf8)
    }

    @Test func theToolRowsChipWrapsUnderItsWords() throws {
        let source = try text("DesignSystem/Components/AIRows.swift")
        let start = try #require(source.range(of: "public struct ToolRow"))
        let end = try #require(source.range(of: "public struct ResultRow"))
        #expect(source[start.upperBound ..< end.lowerBound].contains("AdaptiveRow"))
    }

    @Test func theLastDaysTrailingItemsSitInAnAdaptiveRow() throws {
        let lines = try text("Features/School/LastDaysSections.swift").components(separatedBy: "\n")
        let trailing = ["Chip(", "WorkingTrail()", "Button(\"Gap report\")", "Button(\"Try again\""]
        var found = 0
        for (index, line) in lines.enumerated() where trailing.contains(where: line.contains) {
            found += 1
            let above = lines[max(0, index - 12) ..< index]
            let row = above.lastIndex { $0.contains("AdaptiveRow") || $0.contains("HStack(") }
            #expect(row.map { above[$0].contains("AdaptiveRow") } == true, "line \(index + 1)")
        }
        #expect(found == 4)
    }

    /// The day-column rows (the School list's and the split's) put the day above and the chip under at those sizes.
    @Test func theDayColumnRowsStackAtTheAccessibilitySizes() throws {
        let source = try text("DesignSystem/Components/SchoolRow.swift")
        for name in ["public struct SchoolRow", "public struct PreparationRow"] {
            let start = try #require(source.range(of: name))
            let body = try #require(source[start.upperBound...].range(of: "DayColumn("))
            let before = source[start.upperBound ..< body.lowerBound]
            #expect(before.contains("AdaptiveRow"), "\(name)")
        }
    }
}
