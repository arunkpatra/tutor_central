import Foundation
import Testing
@testable import Domain

/// A group's own lines (the worked example, the figure, the brief) and the groups /ai/plan names.
extension PlanRulesTests {
    @Test func eachGroupHasAWorkedExampleLineAndAFigureLineWhenItsSkillHasATemplate() throws {
        let dev = student("Dev", class: .eight), riya = student("Riya", class: .five)
        let maths = chapter(1, subject: "Mathematics")
        let fractions = (
            chapters: [maths],
            skills: [skill(maths, 1, state: .practising, name: "Compare simple fractions")]
        )
        let draft = PlanRules.plan(input([dev, riya], books: [dev.id: science(dev, taught: 1), riya.id: fractions]))
        let devs = try #require(draft.groups.first { $0.memberIDs == [dev.id] })
        let riyas = try #require(draft.groups.first { $0.memberIDs == [riya.id] })
        let groupLines = { (group: PlanGroup) in
            draft.lines.filter { $0.groupNo == group.number && $0.studentID == nil }
        }
        #expect(groupLines(devs).map(\.kind) == [.workedExample, .brief])
        #expect(groupLines(riyas).map(\.kind) == [.workedExample, .figure])
        #expect(groupLines(riyas)[1].words == "Figure · Compare simple fractions")
    }

    @Test func namingAGroupFillsItsSkillTheTeachLinesTheBriefAndTheFigure() {
        let ann = student("A", class: .eight), ben = student("B", class: .eight)
        let draft = PlanRules.plan(input([ann, ben], books: [:]))
        let named = draft.naming([1: (chapter: "Parts and Wholes", skill: "Compare simple fractions")])
        #expect(named.groups[0].chapter == "Parts and Wholes" && named.groups[0].skill == "Compare simple fractions")
        #expect(named.lines.filter { $0.kind == .teach }.allSatisfy { $0.words == "Teach: Compare simple fractions" })
        #expect(named.lines.first { $0.kind == .brief }?.words == "Your brief · Parts and Wholes")
        #expect(named.lines.contains { $0.kind == .figure })
    }

    @Test func aBriefAskedBeforeAddsTheLineToAYoungerGroup() {
        let riya = student("Riya", class: .five)
        let draft = PlanRules.plan(input([riya], books: [riya.id: science(riya, taught: 1)]))
        #expect(!draft.lines.contains { $0.kind == .brief })
        let asked = draft.addingBriefs(for: ["Chapter 1"])
        #expect(asked.lines.filter { $0.kind == .brief }.map(\.words) == ["Your brief · Chapter 1"])
        #expect(asked.addingBriefs(for: ["Chapter 1"]).lines.count(where: { $0.kind == .brief }) == 1)
    }
}
