import Domain
import Foundation
import Testing
@testable import Data

struct APIBodiesSchoolTests {
    let centre = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let student = UUID(uuidString: "55555555-5555-5555-5555-55555555555d")!

    func json(_ body: some Encodable) throws -> String {
        try String(bytes: JSONEncoder().encode(body), encoding: .utf8) ?? ""
    }

    @Test func theParseBodyCarriesTodayTheSchoolsAndNoStudent() throws {
        let text = try json(ParseSchoolBody(
            source: .text("Unit test on Friday"), today: #require(Day(year: 2026, month: 10, day: 7)),
            schools: ["Vidya Niketan"],
            classLevels: [.eight, .ten], centre: centre
        ))
        #expect(text.contains("\"today\":\"2026-10-07\"") && text.contains("\"schools\":[\"Vidya Niketan\"]"))
        #expect(text.contains("\"classLevels\":[\"8\",\"10\"]") && text.contains("\"text\":\"Unit test on Friday\""))
        #expect(!text.contains("studentId") && !text.contains("image"))
        let photo = try json(ParseSchoolBody(
            source: .image(ImageUpload(data: Data([0xFF, 0xD8]), mediaType: "image/jpeg")),
            today: #require(Day(year: 2026, month: 10, day: 7)), schools: [], classLevels: [], centre: centre
        ))
        #expect(photo.contains("\"image\":{") && photo.contains("\"imageBase64\":\"\\/9g=\"") && !photo
            .contains("\"text\""))
    }

    @Test func theMockBodyIsStrictAndNamesNoStudent() throws {
        let text = try json(MakeMockBody(MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test 3",
            portions: ["Chemical reactions"], pattern: MockPattern(marks: 25, durationMinutes: 40)
        ), centre: centre))
        #expect(text.contains("\"kind\":\"mock\"") && text.contains("\"pattern\":{") && text.contains("\"marks\":25"))
        #expect(text.contains("\"durationMinutes\":40") && !text.contains("sections") && !text.contains("student"))
    }

    @Test func theGapAndTestTomorrowBodiesNameTheStudent() throws {
        let gap = try json(MakeGapBody(GapRequest(
            studentID: student, classLevel: .eight, subject: "Science", daysLeft: 2,
            bySkill: [GapReportContent.Tally(skill: "Balancing", right: 3, of: 10, note: nil)]
        ), centre: centre))
        #expect(gap.contains("\"kind\":\"gap_report\"") && gap
            .contains("\"studentId\":\"55555555-5555-5555-5555-55555555555d\""))
        #expect(gap.contains("\"daysLeft\":2") && gap.contains("\"right\":3") && !gap.contains("note"))
        let message = try json(MakeTestTomorrowBody(TestTomorrowRequest(
            studentID: student, studentName: "Dev Kumar", parentName: "Ramesh Kumar", tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition", language: .hindi, subject: "Science", title: "Science unit test",
            date: #require(Day(year: 2026, month: 10, day: 8)), portions: "chapters 1 and 2", revise: nil
        ), centre: centre))
        #expect(message.contains("\"kind\":\"test_tomorrow\"") && message.contains("\"language\":\"hi\""))
        #expect(message.contains("\"date\":\"2026-10-08\"") && message.contains("\"studentId\"") && !message
            .contains("revise"))
    }

    @Test func aMockSchemeSendsItsGenerationAndTheStudent() throws {
        let generation = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let text = try json(CheckBody(
            centreId: "c", pages: [], scheme: SchemeBody(.mock(generationID: generation, artefactID: UUID())),
            studentName: "Dev", studentId: student.uuidString.lowercased()
        ))
        #expect(text
            .contains("\"scheme\":{\"generationId\":\"11111111-1111-1111-1111-111111111111\",\"kind\":\"mock\"}")
            || text.contains("\"kind\":\"mock\",\"generationId\":\"11111111-1111-1111-1111-111111111111\""))
        #expect(text.contains("\"studentId\":\"55555555-5555-5555-5555-55555555555d\""))
        let typed = try json(CheckBody(
            centreId: "c",
            pages: [],
            scheme: SchemeBody(.typed("Q1")),
            studentName: "Dev",
            studentId: nil
        ))
        #expect(!typed.contains("studentId"))
    }

    @Test func aParsedItemReadsANullDate() throws {
        let data = Data("""
        {"id":"11111111-1111-1111-1111-111111111111","result":{"items":[{"kind":"exam","title":"Unit test",\
        "subject":"Science","date":null,"endDate":null,"classLevel":"8","school":null,"studentName":null,\
        "portions":null},{"kind":"holiday","title":"Dasara","subject":null,"date":"2026-10-19",\
        "endDate":"2026-10-21","classLevel":null,"school":"Vidya Niketan","studentName":null,"portions":null}]}}
        """.utf8)
        let answer = try JSONDecoder().decode(MadeEnvelope<ParseSchoolResult>.self, from: data)
        #expect(answer.result.items[0].date == nil && answer.result.items[0].classLevel == .eight)
        #expect(answer.result.items[1].endDate == Day(year: 2026, month: 10, day: 21) && answer.result.items[1]
            .kind == .holiday)
    }
}

@MainActor struct FakeAIRepositorySchoolTests {
    let centre = UUID()
    let today = Day(year: 2026, month: 10, day: 7)!

    @Test func theFakeAnswersTheSamplesAndRecordsEachCall() async throws {
        let ai = FakeAIRepository()
        let photo = try await ai.parseSchool(
            .image(ImageUpload(data: Data([1]), mediaType: "image/jpeg")), today: today, schools: [], classLevels: [],
            centre: centre
        )
        #expect(photo.items.map(\.kind) == [.exam, .exam])
        let text = try await ai.parseSchool(
            .text("Dear Parents"),
            today: today,
            schools: [],
            classLevels: [],
            centre: centre
        )
        #expect(text.items.map(\.kind) == [.exam, .homework, .holiday])
        let mock = try await ai.makeMock(
            MockRequest(
                classLevel: .eight,
                subject: "Science",
                title: "T",
                portions: ["x"],
                pattern: MockPattern(marks: 40, durationMinutes: 60)
            ),
            centre: centre
        )
        #expect(mock.content.marks == 40 && mock.content.title == "T")
        let gap = try await ai.makeGapReport(
            GapRequest(studentID: UUID(), classLevel: .eight, subject: "Science", daysLeft: 2, bySkill: []),
            centre: centre
        )
        #expect(gap.days.count == 2)
        let message = try await ai.makeTestTomorrow(
            TestTomorrowRequest(
                studentID: UUID(), studentName: "Dev Kumar", parentName: nil, tutorName: "Meera Nair", centreName: "B",
                language: .hindi, subject: "Science", title: "Test", date: today, portions: nil, revise: nil
            ),
            centre: centre
        )
        #expect(message.english.contains("Dev") && !message.message.isEmpty)
        #expect(ai.parseCalls.count == 2 && ai.mockCalls.count == 1 && ai.gapCalls.count == 1 && ai.messageCalls
            .count == 1)
    }

    @Test func aScriptedFailureThrows() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.offline)
        await #expect(throws: APIFailure.self) {
            _ = try await ai.parseSchool(.text("x"), today: today, schools: [], classLevels: [], centre: centre)
        }
    }

    /// Review Important 3, seen in the cost run: a real mock gave 20 skills and the API takes 12, three days at most
    /// and notes of 300; the body sends the twelve weakest, the days clamped, the notes cut.
    @Test func theGapBodyKeepsWithinTheAPIsLimits() {
        let tallies = (1 ... 20).map { index in
            GapReportContent.Tally(
                skill: "Skill \(index)", right: index % 3, of: 3, note: String(repeating: "n", count: 400)
            )
        }
        let body = MakeGapBody(
            GapRequest(studentID: UUID(), classLevel: .eight, subject: "Science", daysLeft: 4, bySkill: tallies),
            centre: UUID()
        )
        #expect(body.daysLeft == 3 && body.bySkill.count == 12)
        #expect(body.bySkill.allSatisfy { ($0.note?.count ?? 0) <= 300 })
        #expect(body.bySkill.allSatisfy { $0.right < 2 }) // the weakest first: none with 2 of 3 when twelve are fewer
        let order = tallies.map(\.skill)
        let sent = body.bySkill.map(\.skill)
        #expect(sent == order.filter { sent.contains($0) }) // in the mock's order
    }
}
