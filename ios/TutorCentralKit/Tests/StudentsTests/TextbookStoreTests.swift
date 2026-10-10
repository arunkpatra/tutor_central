import Data
import Domain
import Foundation
import Testing
import UIKit
@testable import Students

@MainActor struct TextbookStoreTests {
    let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg")

    func store(
        ai: FakeAIRepository = FakeAIRepository(), textbooks: FakeTextbooksRepository = FakeTextbooksRepository(),
        online: Bool = true
    ) async throws -> TextbookStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }, schools: FakeSchoolsRepository()
        )
        await register.load()
        textbooks.students = register.students
        let riya = try #require(register.student(FakeStudentsRepository.riya))
        return TextbookStore(
            student: riya, school: FakeSchoolsRepository.vidya, register: register, ai: ai, textbooks: textbooks,
            online: { online }
        )
    }

    @Test func theIntroNamesTheSchoolAndClassAndNeedsASubject() async throws {
        let store = try await store()
        #expect(store.phase == .intro && !store.canRead)
        #expect(Array(store.subjects.prefix(2)) == ["Mathematics", "Science"])
        store.subject = "Mathematics"
        #expect(store.canRead)
        #expect(store.subjectHelper == "Vidya Niketan, class 5. Riya's classmates there get the same chapters.")
    }

    @Test func readingShowsTheChaptersAndKeepSavesOnceAndCopiesToTheClass() async throws {
        let ai = FakeAIRepository(), textbooks = FakeTextbooksRepository()
        let store = try await store(ai: ai, textbooks: textbooks)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: nil)
        #expect(store.phase == .chapters && store.chapters.count == 5 && store.chaptersTitle == "5 chapters read")
        #expect(textbooks.textbooks.isEmpty)
        store.rename(at: 0, to: "The Fish Tale (long)")
        store.remove(at: 4)
        #expect(store.chapters.count == 4 && store.keepTitle == "Keep 4 chapters" && store.chapters.last?.position == 4)
        #expect(await store.keep())
        #expect(textbooks.textbooks.count == 1 && textbooks.textbooks[0].title == "Math-Magic 5")
        #expect(textbooks.textbooks[0].chapters.count == 4 && textbooks.textbooks[0].chapters[0]
            .name == "The Fish Tale (long)")
        #expect(textbooks.copyToClassCalls == [textbooks.textbooks[0].id])
        #expect(try await textbooks.chapters(student: FakeStudentsRepository.riya).count == 4)
    }

    @Test func nothingIsKeptOfThePhoto() async throws {
        let ai = FakeAIRepository(), textbooks = FakeTextbooksRepository()
        let store = try await store(ai: ai, textbooks: textbooks)
        store.subject = "Science"
        await store.read(page, thumbnail: nil)
        _ = await store.keep()
        #expect(ai.textbooks.count == 1)
        #expect(textbooks.lastWrittenValues?["photo_path"] == nil)
        #expect(Mirror(reflecting: store).children.allSatisfy { !($0.value is ImageUpload) })
    }

    @Test func aFailedReadSaysSoAndKeepsTheIntroAndOfflineIsRefusedBeforeTheCall() async throws {
        let ai = FakeAIRepository()
        ai.script = .failure(.refused("Couldn't read the chapters from this photo. Try a flatter, brighter one."))
        let store = try await store(ai: ai)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: nil)
        #expect(store.phase == .intro)
        #expect(store.failure == "Couldn't read the chapters from this photo. Try a flatter, brighter one.")
        let offline = try await self.store(ai: ai, online: false)
        offline.subject = "Mathematics"
        await offline.read(page, thumbnail: nil)
        #expect(offline.failure == OfflineRefusal.words(for: .textbook) && ai.textbooks.count == 1)
    }

    @Test func aSecondCaptureReplacesTheBookAndTheCopyKeepsProgress() async throws {
        let textbooks = FakeTextbooksRepository()
        let store = try await store(textbooks: textbooks)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: nil)
        _ = await store.keep()
        let first = try #require(try await textbooks.skills(student: FakeStudentsRepository.riya).first)
        try await textbooks.setState(skillID: first.id, .secure)
        let again = try await self.store(textbooks: textbooks)
        again.subject = "Mathematics"
        await again.read(page, thumbnail: nil)
        _ = await again.keep()
        #expect(textbooks.textbooks.count == 1)
        #expect(try await textbooks.skills(student: FakeStudentsRepository.riya).first { $0.id == first.id }?
            .state == .secure)
    }

    @Test func aChapterIsAddedAndItsSkillsChanged() async throws {
        let store = try await store()
        store.subject = "Mathematics"
        await store.read(page, thumbnail: nil)
        store.add(name: "Revision", skills: ["Mixed sums"])
        #expect(store.chapters.last?.position == 6 && store.chapters.last?.name == "Revision")
        store.setSkills(at: 0, ["Compare lengths"])
        #expect(store.chapters[0].skills == ["Compare lengths"] && TextbookStore
            .skillsLine(store.chapters[0]) == "1 skill read")
    }
}
