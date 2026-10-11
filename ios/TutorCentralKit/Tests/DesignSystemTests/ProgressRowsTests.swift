import Testing
@testable import DesignSystem

/// The Progress parts (components.md 10.7): a row read aloud as it reads, the hero's three columns.
struct ProgressRowsTests {
    @Test func aRowReadsItsNameStatusLineAndPercent() {
        #expect(StudentProgressRow.spoken(
            name: "Dev Kumar",
            status: "Not on track",
            line: "3 skills secure",
            percent: "41%"
        )
            == "Dev Kumar, Not on track, 3 skills secure, 41%")
    }

    @Test func theHeroHasItsThreeColumnsInTheirTones() {
        let columns = ProgressHeroCard.columns(skillsSecure: 38, rightText: "71%", notOnTrack: 2, label: "not on track")
        #expect(columns.map(\.value) == ["38", "71%", "2"])
        #expect(columns.map(\.label) == ["skills made secure", "checks right", "not on track"])
        #expect(columns.map(\.tone.name) == ["ok", "text", "overdue"])
    }
}
