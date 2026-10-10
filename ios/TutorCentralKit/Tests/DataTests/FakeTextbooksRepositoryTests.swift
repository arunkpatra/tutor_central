import Domain
import Foundation
import Testing
@testable import Data

@MainActor
struct FakeTextbooksRepositoryTests {
    let centre = FakeSchoolsRepository.centre
    let student = UUID()

    func book(subject: String = "Mathematics", chapters: [TextbookChapter]) -> Textbook {
        Textbook(
            id: UUID(), schoolID: FakeSchoolsRepository.vidya.id, classLevel: .five, subject: subject,
            title: "Maths 5", publisher: nil, edition: nil, chapters: chapters
        )
    }

    @Test func aSecondCaptureForTheSameSchoolClassAndSubjectReplacesTheFirst() async throws {
        let repo = FakeTextbooksRepository()
        _ = try await repo.save(
            book(chapters: [TextbookChapter(position: 1, name: "Old", skills: ["a"])]),
            centre: centre
        )
        let second = try await repo.save(
            book(chapters: [TextbookChapter(position: 1, name: "New", skills: ["a"])]), centre: centre
        )
        #expect(try await repo.textbooks(centre: centre) == [second])
    }

    @Test func copyingTwiceGivesTheSameChaptersAndKeepsOtherSubjects() async throws {
        let repo = FakeTextbooksRepository()
        let saved = try await repo.save(book(chapters: [
            TextbookChapter(position: 1, name: "Shapes", skills: ["Circles", "Squares"]),
            TextbookChapter(position: 2, name: "Numbers", skills: ["Counting", "Tens"]),
        ]), centre: centre)
        let english = try await repo.save(
            book(subject: "English", chapters: [TextbookChapter(position: 1, name: "Sounds", skills: ["a"])]),
            centre: centre
        )
        try await repo.copyChapters(of: english.id, to: student, centre: centre)
        try await repo.copyChapters(of: saved.id, to: student, centre: centre)
        try await repo.copyChapters(of: saved.id, to: student, centre: centre)
        let chapters = try await repo.chapters(student: student)
        #expect(chapters.map(\.name).sorted() == ["Numbers", "Shapes", "Sounds"])
        #expect(try await repo.skills(student: student).count == 5)
        let circles = try #require(try await repo.skills(student: student).first { $0.name == "Circles" })
        try await repo.setState(skillID: circles.id, .taught)
        #expect(try await repo.skills(student: student).first { $0.id == circles.id }?.state == .taught)
    }
}
