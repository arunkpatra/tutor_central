import Domain
import Foundation
import Testing
@testable import Data

/// Phase 14's calls: the bodies within the API's limits, the fake's answers, and the client's new answers (D68).
enum ParentsRequests {
    static let dev = FakeStudentsRepository.dev
    static let monday = Day(year: 2026, month: 10, day: 5)!

    static func note(
        taught: [String] = ["Balancing equations", "Types of reactions"],
        right: String? = "8 of 12 checks",
        attendance: String? = "absent 2 of 3 classes"
    ) -> NoteRequest {
        NoteRequest(
            studentID: dev, studentName: "Dev Kumar", parentName: "Ramesh Kumar", tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition", classLevel: .eight, language: .hindi, weekMonday: monday,
            week: NoteRequest.Week(
                taught: taught, right: right, practise: ["The numbers in front of a formula"],
                coming: ["Acids, bases and salts", "the unit test on Fri 16 Oct"], attendance: attendance
            )
        )
    }

    static let canDo = CanDoRequest(
        studentID: FakeStudentsRepository.sahil, studentName: "Sahil Verma", parentName: "Deepak Verma",
        tutorName: "Meera Nair", centreName: "Bright Minds Tuition", classLevel: .two, language: .kannada,
        facts: CanDoFacts(
            movedUp: [.init(area: .reading, step: "Sentences")], canDo: ["Read short sentences", "Count to 99"],
            atHome: "One page a day from the picture book", next: ["Writing words", "Adding to 20"]
        )
    )

    static let notOnTrack = NotOnTrackRequest(
        studentID: dev, studentName: "Dev Kumar", parentName: "Ramesh Kumar", tutorName: "Meera Nair",
        centreName: "Bright Minds Tuition", classLevel: .eight, language: .hindi,
        facts: NotOnTrackMessage.Facts(
            hard: ["balancing equations"], reasons: ["3 of 10 on the mock"],
            doing: "teach it again with a worked example in the next class", atHome: NotOnTrackMessage.atHome
        )
    )

    static func readMarks(pages: Int, subjects: [String]) -> ReadMarksRequest {
        ReadMarksRequest(
            studentID: FakeStudentsRepository.hemanth, studentName: "Hemanth Reddy",
            pages: Array(repeating: ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg"), count: pages),
            subjects: subjects
        )
    }
}

struct APIBodiesParentsTests {
    func json(_ body: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try #require(String(bytes: encoder.encode(body), encoding: .utf8))
    }

    @Test func theNoteBodyCarriesTheFactsWithinTheAPIsLimits() throws {
        let body = MakeNoteBody(
            ParentsRequests.note(taught: Array(repeating: "A long skill name", count: 9)),
            centre: UUID()
        )
        #expect(body.week.taught.count == 6 && body.week.monday == "2026-10-05" && body.language == "hi")
        #expect(body.kind == "note" && body.classLevel == "8")
        let json = try json(body)
        #expect(json.contains("\"attendance\":\"absent 2 of 3 classes\"") && json.contains("\"studentId\""))
    }

    @Test func aMissingFactIsLeftOutOfTheBodyNotSentEmpty() throws {
        let json = try json(MakeNoteBody(ParentsRequests.note(right: nil, attendance: nil), centre: UUID()))
        #expect(!json.contains("\"right\"") && !json.contains("\"attendance\""))
    }

    @Test func theReadMarksBodyCarriesTwoPagesAtMostAndTheSubjects() {
        let body = ReadMarksBody(
            ParentsRequests.readMarks(pages: 3, subjects: ["Mathematics", "Science"]),
            centre: UUID()
        )
        #expect(body.pages.count == 2 && body.subjects == ["Mathematics", "Science"])
    }

    @Test func theCanDoAndNotOnTrackBodiesReadAsTheSchemas() throws {
        let canDo = try json(MakeCanDoBody(ParentsRequests.canDo, centre: UUID()))
        #expect(canDo.contains(#""movedUp":[{"area":"reading","step":"Sentences"}]"#))
        #expect(canDo.contains(#""kind":"can_do""#) && canDo.contains(#""classLevel":"2""#))
        let not = try json(MakeNotOnTrackBody(ParentsRequests.notOnTrack, centre: UUID()))
        #expect(not.contains(#""hard":["balancing equations"]"#) && not.contains(#""kind":"not_on_track""#))
    }
}

@MainActor struct FakeAIRepositoryParentsTests {
    @Test func theFakeAnswersTheBoardsNotesAndRecordsTheCalls() async throws {
        let ai = FakeAIRepository()
        let note = try await ai.makeNote(ParentsRequests.note(), centre: UUID())
        #expect(note.message.hasPrefix("नमस्ते") && note.english.contains("Dev learnt to balance chemical equations"))
        #expect(ai.noteCalls.count == 1 && ai.noteCalls.first?.language == .hindi)
        let canDo = try await ai.makeCanDo(ParentsRequests.canDo, centre: UUID())
        #expect(canDo.message.hasPrefix("ನಮಸ್ಕಾರ"))
        let not = try await ai.makeNotOnTrack(ParentsRequests.notOnTrack, centre: UUID())
        #expect(not.english.contains("Could we talk for five minutes this week?"))
        let marks = try await ai.readMarks(ParentsRequests.readMarks(pages: 1, subjects: []), centre: UUID())
        #expect(marks.marks.count == 3 && marks.marks[2].date == nil && marks.marks[0].score == 14)
    }

    @Test func aScriptedFailureOnOneKindLeavesTheOthers() async {
        let ai = FakeAIRepository()
        ai.scriptByKind[.note] = .failure(.service)
        await #expect(throws: APIFailure.service) { try await ai.makeNote(ParentsRequests.note(), centre: UUID()) }
        #expect(await (try? ai.makeCanDo(ParentsRequests.canDo, centre: UUID())) != nil)
    }
}

extension APIClientTests {
    @Test func a503ReadsAsTheConnectionWords() async {
        let (client, _) = Self.client(
            status: 503, body: #"{"error":"Couldn't reach the service. Try again.","reason":"unreachable"}"#
        )
        await #expect(throws: APIFailure.offline) { try await client.makeNote(
            ParentsRequests.note(),
            centre: Self.centre
        ) }
    }

    @Test func a501OrA500NeverShowsTheAPIsWords() async {
        for (status, body) in [(501, #"{"error":"not yet","route":"/ai/make"}"#), (500, #"{"error":"boom"}"#)] {
            let (client, _) = Self.client(status: status, body: body)
            await #expect(throws: APIFailure.service) {
                try await client.makeNote(ParentsRequests.note(), centre: Self.centre)
            }
        }
    }

    @Test func aStudentsMissingConsentReadsInTheStudentWords() async {
        let (client, _) = Self.client(
            status: 403, body: #"{"error":"Dev's parent hasn't agreed yet.","reason":"student_consent"}"#
        )
        await #expect(throws: APIFailure.studentConsent("Dev's parent hasn't agreed yet.")) {
            try await client.makeNote(ParentsRequests.note(), centre: Self.centre)
        }
        #expect(APIFailure.studentConsent("Dev's parent hasn't agreed yet.")
            .message == APIFailure.studentAlert)
    }

    @Test func readMarksPostsThePagesAndDecodesTheRows() async throws {
        let body = #"{"id":"fbc6ae19-2769-4934-bf10-c830207fd6a3","result":{"marks":["#
            + #"{"subject":"Mathematics","test":"Unit test 2","date":"2026-09-28","score":14,"max":25},"#
            + #"{"subject":"Hindi","test":"Unit test 2","date":null,"score":11.5,"max":25}]}}"#
        let (client, recorder) = Self.client(status: 200, body: body)
        let answer = try await client.readMarks(
            ParentsRequests.readMarks(pages: 1, subjects: ["Mathematics"]), centre: Self.centre
        )
        #expect(answer.marks.count == 2 && answer.marks[1].date == nil && answer.marks[1].score == 12)
        #expect(answer.marks[0].date == Day(year: 2026, month: 9, day: 28))
        #expect(recorder.requests.first?.url?.path == "/ai/read-marks")
    }
}
