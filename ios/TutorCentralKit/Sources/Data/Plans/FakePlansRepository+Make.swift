import Domain
import Foundation

public extension FakePlansRepository {
    nonisolated static let madeSheetID = UUID(uuidString: "abababab-0000-0000-0015-000000000001")!
    nonisolated static let madeMockID = UUID(uuidString: "abababab-0000-0000-0015-000000000002")!
    nonisolated static let madeBriefID = UUID(uuidString: "abababab-0000-0000-0015-000000000003")!

    /// What Make made on the boards' Wednesday (P10-Make's Recent): Group 1's sheet, Dev's mock, the Chemical
    /// reactions brief, each kept with `made_from = 'make'` and its target's words.
    nonisolated static let madeRecent: [Artefact] = {
        let india = DayHeading.india
        let at = { (minute: Int) in
            india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: minute)) ?? Date()
        }
        let group = MakeFor(
            target: .group(plan: planID, number: 1), title: "Group 1", line: "Class 8 Science · Balancing equations",
            level: .eight, subject: "Science", skills: ["Balancing equations"]
        )
        let dev = MakeFor(
            target: .student(FakeStudentsRepository.dev), title: "For Dev", line: "Class 8 Science", level: .eight,
            subject: "Science", skills: ["Chemical reactions"]
        )
        let level = MakeFor(
            target: .classLevel(.eight), title: "Class 8", line: "Science · Chemical reactions", level: .eight,
            subject: "Science", skills: ["Chemical reactions"]
        )
        let mock = MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"],
            pattern: .default(for: .eight), schoolItemID: nil
        )
        return [
            Artefact(
                id: madeSheetID, kind: .sheet, source: .made, title: "Balancing equations · sheet 1",
                content: .sheet(AISamples.sheet(questions: 10, forHomework: false, light: false)), photoPath: nil,
                studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: at(40), madeFrom: "make", madeFor: group
            ),
            Artefact(
                id: madeMockID, kind: .mock, source: .made, title: "Science unit test 3 · mock",
                content: .mock(AISamples.mock(mock)), photoPath: nil, studentID: FakeStudentsRepository.dev,
                planID: nil, regeneratedFrom: nil, madeAt: at(35), madeFrom: "make", madeFor: dev
            ),
            Artefact(
                id: madeBriefID, kind: .brief, source: .made, title: "Chemical reactions",
                content: .brief(AISamples.brief), photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil,
                madeAt: at(30), madeFrom: "make", madeFor: level
            ),
        ]
    }()
}
