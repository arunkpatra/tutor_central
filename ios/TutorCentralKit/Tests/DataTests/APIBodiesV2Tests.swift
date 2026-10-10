import Domain
import Foundation
import Testing
@testable import Data

struct APIBodiesV2Tests {
    func json(_ body: some Encodable) throws -> String {
        try String(bytes: JSONEncoder().encode(body), encoding: .utf8) ?? ""
    }

    @Test func aSheetBodyNamesTheSkillsCountAndReason() throws {
        let body = MakeSheetBody(
            centreId: "c", classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8,
            forHomework: false, reason: "easier"
        )
        let text = try json(body)
        #expect(text.contains("\"kind\":\"sheet\""))
        #expect(text.contains("\"forHomework\":false"))
        #expect(text.contains("\"reason\":\"easier\""))
    }

    @Test func noBodyCarriesAStudent() throws {
        let bodies: [any Encodable] = [
            MakeSheetBody(
                centreId: "c", classLevel: "8", subject: "Science", skills: ["x"], questions: 10, forHomework: true,
                reason: nil
            ),
            MakeWorkedExampleBody(centreId: "c", classLevel: "8", subject: "Science", skill: "x"),
            MakeFigureBody(centreId: "c", figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "x"),
            MakeBriefBody(centreId: "c", classLevel: "8", subject: "Science", chapter: "x"),
            PlanBody(
                centreId: "c", classId: nil, date: "2026-10-07", month: 10,
                groups: [.init(groupNo: 1, classLevel: "8", subject: "Science")]
            ),
        ]
        for body in bodies {
            #expect(try !json(body).lowercased().contains("student"))
        }
    }
}
