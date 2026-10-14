import Foundation
import Supabase
import Testing
@testable import Data
@testable import Domain

/// D107: `record_feedback`'s arguments as the app sends them; the fake lists what it got.
struct FeedbackRepositoryTests {
    let centre = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let generation = UUID(uuidString: "a0000000-0000-4000-8000-000000000001")!

    @Test func anEditSendsTheTextAReasonItsWordsAReplacementByPhotoNoPhoto() {
        let edit = SupabaseFeedbackRepository.params(.edit(generation, sent: "नमस्ते"), centre: centre)
        #expect(edit["p_kind"] == .string("edit") && edit["p_revised"] == .string("नमस्ते") && edit["p_reason"] == .null)
        #expect(edit["p_generation"] == .string("a0000000-0000-4000-8000-000000000001"))
        let again = SupabaseFeedbackRepository.params(.again(generation, reason: "Less about marks"), centre: centre)
        #expect(again["p_reason"] == .string("Less about marks") && again["p_revised"] == .null)
        let photo = SupabaseFeedbackRepository.params(.replace(generation, with: .photo), centre: centre)
        #expect(photo["p_revised"] == .object(["photo": .bool(true)]))
    }

    @MainActor @Test func theFakeListsWhatItGot() async throws {
        let fake = FakeFeedbackRecorder()
        try await fake.record(.again(generation, reason: "Warmer"), centre: centre)
        #expect(fake.recorded.map(\.kind) == [.again])
    }

    @Test func theNoteAndTheMocksBodiesCarryTheirReason() throws {
        let note = try NoteRequest(
            studentID: generation, studentName: "Dev Kumar", parentName: "Ramesh Kumar", tutorName: "Meera",
            centreName: "Bright Minds", classLevel: .eight, language: .hindi, weekMonday: #require(Day(
                year: 2026,
                month: 10,
                day: 5
            )),
            week: .init(taught: ["Balancing equations"], right: nil, practise: [], coming: [], attendance: nil)
        ).asking("Less about marks")
        let body = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeNoteBody(
            note,
            centre: centre
        ))) as? [String: Any]
        #expect(body?["reason"] as? String == "Less about marks")
        #expect(try (JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeNoteBody(
            note.asking(nil),
            centre: centre
        ))) as? [String: Any])?["reason"] == nil)
        let mock = MockRequest(
            classLevel: .eight,
            subject: "Science",
            title: "Unit test",
            portions: ["Chemical reactions"],
            pattern: MockPattern(marks: 25, durationMinutes: 40),
            reason: "Harder"
        )
        let mockBody = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeMockBody(
            mock,
            centre: centre
        ))) as? [String: Any]
        #expect(mockBody?["reason"] as? String == "Harder")
    }
}
