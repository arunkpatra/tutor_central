import Foundation
import Testing
@testable import Domain

struct SessionCloseTests {
    @Test func aSessionCloseRoundTripsAsJSON() throws {
        let close = try SessionClose(
            classID: UUID(), date: #require(Day(year: 2026, month: 10, day: 7)), marks: [UUID(): .present],
            checks: [.init(studentID: UUID(), skillID: UUID(), question: "Q", correct: true, isPlacement: false)],
            homework: [.init(studentID: UUID(), artefactID: nil)],
            track: [UUID(): .init(status: .watch, reasons: ["Absent 2 times in four weeks"])],
            states: [SkillStateChange(skillID: UUID(), state: .practising)]
        )
        let back = try JSONDecoder().decode(SessionClose.self, from: JSONEncoder().encode(close))
        #expect(back == close)
    }
}
