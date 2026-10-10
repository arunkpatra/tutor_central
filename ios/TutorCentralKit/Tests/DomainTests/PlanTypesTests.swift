import Foundation
import Testing
@testable import Domain

struct PlanTypesTests {
    func artefact(_ id: UUID, _ kind: ArtefactKind, _ content: ArtefactContent, student: UUID? = nil) -> Artefact {
        Artefact(
            id: id, kind: kind, source: .made, title: "t", content: content, photoPath: nil, studentID: student,
            planID: nil, regeneratedFrom: nil, madeAt: FakeClock.oct7at1635
        )
    }

    func item(_ student: UUID, _ kind: PlanLineKind, _ words: String, artefact: UUID) -> PlanItem {
        PlanItem(
            id: UUID(), studentID: student, groupNo: 1, kind: kind, skillID: nil, words: words, artefactID: artefact,
            doneAt: nil, skippedAt: nil, movedFrom: nil
        )
    }

    @Test func aRecordFindsAStudentsItemsAndTheGroupsArtefacts() throws {
        let dev = UUID(), riya = UUID(), sheetID = UUID(), checksID = UUID(), ownChecks = UUID()
        let homework = SheetContent(title: "s", instructions: nil, questions: [], forHomework: true, light: false)
        let artefacts = [
            artefact(sheetID, .sheet, .sheet(homework)),
            artefact(checksID, .check, .check(CheckContent(questions: [], placement: false))),
            artefact(ownChecks, .check, .check(CheckContent(questions: [], placement: true)), student: riya),
        ]
        let record = try PlanRecord(
            id: UUID(), classID: UUID(), date: #require(Day(iso: "2026-10-07")), madeAt: FakeClock.oct7at1635,
            groups: [],
            items: [
                item(dev, .homework, "Homework sheet 1", artefact: sheetID),
                item(dev, .check, "Check 3", artefact: checksID),
                item(riya, .check, "Placement, her first checks", artefact: ownChecks),
            ],
            artefacts: artefacts, sessionID: nil
        )
        #expect(record.items(of: dev).count == 2)
        #expect(record.artefact(group: 1, kind: .sheet, homework: true)?.id == sheetID)
        #expect(record.artefact(group: 1, kind: .sheet, homework: false) == nil)
        #expect(record.checks(for: dev)?.id == checksID)
        #expect(record.checks(for: riya)?.id == ownChecks)
    }
}
