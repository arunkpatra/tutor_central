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

    @Test func copyToClassReachesEveryStudentOfTheSchoolAndClassAndCopyAllReachesALateJoiner() async throws {
        let repo = FakeTextbooksRepository()
        let book = try await repo.save(Textbook(
            id: UUID(), schoolID: FakeSchoolsRepository.vidya.id, classLevel: .ten, subject: "Mathematics",
            title: "Maths 10", publisher: nil, edition: nil,
            chapters: [TextbookChapter(position: 1, name: "Real Numbers", skills: ["Find the HCF by Euclid's method"])]
        ), centre: centre)
        repo.students = FakeStudentsRepository.seed
        let copied = try await repo.copyToClass(textbookID: book.id, centre: centre)
        #expect(copied == 3) // Akshita, Ananya, Hemanth
        #expect(repo.copyToClassCalls == [book.id])
        let late = UUID()
        repo.students.append(Student(
            id: late, name: "Late", classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil,
            dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: .ten,
            schoolID: FakeSchoolsRepository.vidya.id
        ))
        #expect(try await repo.copyAll(to: late, centre: centre) == 1)
        #expect(try await repo.chapters(student: late).count == 1)
        #expect(repo.copyAllCalls == [late])
    }

    @Test func addChapterAppendsAfterTheSubjectsLast() async throws {
        let repo = FakeTextbooksRepository.seeded()
        let hemanth = FakeStudentsRepository.hemanth
        let added = try await repo.addChapter(
            student: hemanth, subject: "Mathematics", name: "Extra practice", skills: ["Solve mixed sums"],
            centre: centre
        )
        #expect(added.position == 15)
        #expect(try await repo.skills(student: hemanth)
            .contains { $0.chapterID == added.id && $0.name == "Solve mixed sums" })
    }

    @Test func theSeedHasHemanthsBookAndSahilsLadder() async throws {
        let repo = FakeTextbooksRepository.seeded()
        let maths = try await repo.chapters(student: FakeStudentsRepository.hemanth)
        #expect(maths.count == 14 && maths[0].name == "Real Numbers")
        let skills = try await repo.skills(student: FakeStudentsRepository.hemanth)
        #expect(skills.filter { $0.chapterID == maths[0].id }.allSatisfy { $0.state == .secure })
        let ladder = try await repo.chapters(student: FakeStudentsRepository.sahil)
        #expect(Set(ladder.compactMap(\.ladder)) == [.reading, .writing, .numbers])
    }

    @Test func aRecaptureKeepsTheBooksIdAndEachStudentsStates() async throws {
        let repo = FakeTextbooksRepository()
        repo.students = FakeStudentsRepository.seed
        let first = try await repo.save(
            book(chapters: [TextbookChapter(position: 1, name: "Old", skills: ["a"])]),
            centre: centre
        )
        _ = try await repo.copyToClass(textbookID: first.id, centre: centre)
        let riya = FakeStudentsRepository.riya
        let skill = try #require(try await repo.skills(student: riya).first)
        try await repo.setState(skillID: skill.id, .secure)
        let second = try await repo.save(
            book(chapters: [TextbookChapter(position: 1, name: "New", skills: ["a"])]),
            centre: centre
        )
        #expect(second.id == first.id && repo.textbooks.count == 1)
        _ = try await repo.copyToClass(textbookID: second.id, centre: centre)
        #expect(try await repo.chapters(student: riya).map(\.name) == ["New"])
        #expect(try await repo.skills(student: riya).first?.state == .secure)
    }

    @Test func theLadderIsMadeOnceForAStudentWhoNeedsIt() async throws {
        let repo = FakeTextbooksRepository()
        let young = UUID()
        try await repo.ensureLadder(student: young, centre: centre)
        try await repo.ensureLadder(student: young, centre: centre)
        let chapters = try await repo.chapters(student: young)
        #expect(Set(chapters.compactMap(\.ladder)) == [.reading, .writing, .numbers] && chapters.count == 3)
        #expect(try await repo.skills(student: young).count == 15)
    }
}
