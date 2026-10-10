import Domain
import Foundation
import Testing
@testable import Data

struct PlanRowTests {
    @Test func aPlanRowReadsItsGroupsItemsAndArtefacts() throws {
        let json = #"""
        {"id":"7a1f0000-0000-0000-0000-000000000001","class_id":"7a1f0000-0000-0000-0000-000000000002",
         "date":"2026-10-07","made_at":"2026-10-07T11:05:00+00:00","session_id":null,
         "groups":[{"number":1,"subject":"Science","chapter":"Chemical reactions","skill":"Balancing equations",
          "classLevels":["8"],"memberIDs":["7a1f0000-0000-0000-0000-000000000004"],"skillID":null}],
         "subjects":{"1":"Science"},
         "plan_items":[{"id":"7a1f0000-0000-0000-0000-000000000003",
          "student_id":"7a1f0000-0000-0000-0000-000000000004","group_no":1,"kind":"teach","skill_id":null,
          "words":"Teach: Balancing equations","artefact_id":null,"done_at":null,"skipped_at":null,
          "moved_from":null},
                       {"id":"7a1f0000-0000-0000-0000-000000000006",
                        "student_id":"7a1f0000-0000-0000-0000-000000000004","group_no":1,"kind":"practise",
                        "skill_id":null,"words":"Practise set 1",
                        "artefact_id":"7a1f0000-0000-0000-0000-000000000005","done_at":null,"skipped_at":null,
                        "moved_from":null}],
         "artefacts":[{"id":"7a1f0000-0000-0000-0000-000000000005","kind":"sheet","source":"made",
          "title":"Balancing equations · sheet 1","content":{"title":"B","instructions":null,"questions":[],
          "for_homework":false,"light":false},"photo_path":null,"student_id":null,
          "plan_id":"7a1f0000-0000-0000-0000-000000000001","regenerated_from":null,
          "created_at":"2026-10-07T11:06:00+00:00"}]}
        """#
        let record = try PostgRESTDecoder.make().decode(PlanRow.self, from: Data(json.utf8)).record
        #expect(record.groups[0].skill == "Balancing equations")
        #expect(record.items[0].words == "Teach: Balancing equations")
        let sheet = try #require(record.artefacts.first)
        if case .sheet = sheet.content {} else {
            Issue.record("not a sheet")
        }
    }

    @Test func makeParamsCarryTheDraftAsTheFunctionTakesIt() {
        let params = SupabasePlansRepository.makeParams(PlanSamples.sampleDraft, centre: UUID())
        #expect(params["p_groups"] != nil)
        #expect(params["p_subjects"] != nil)
        guard case let .array(items)? = params["p_items"],
              case let .object(first)? = items.first else { Issue.record("no items"); return }
        #expect(first["kind"] == .string("teach"))
        #expect(first["words"] != nil)
    }

    @Test func keepParamsEncodeTheContentWithSnakeCaseAndNoStudentForAGroup() throws {
        let artefact = NewArtefact(
            kind: .sheet,
            source: .made,
            title: "t",
            content: .sheet(SheetContent(
                title: "t",
                instructions: nil,
                questions: [],
                forHomework: true,
                light: false
            )),
            photoPath: nil,
            generationID: UUID(),
            regeneratedFrom: nil
        )
        let params = try SupabasePlansRepository.keepParams(
            artefact,
            to: ArtefactLink(plan: UUID(), group: 1, student: nil, itemKind: .homework), centre: UUID()
        )
        guard case let .object(row)? = params["p_artefact"],
              case let .object(content)? = row["content"] else { Issue.record("no artefact"); return }
        #expect(content["for_homework"] == .bool(true))
        #expect(params["p_student"] == .null)
        #expect(params["p_item_kind"] == .string("homework"))
    }
}
