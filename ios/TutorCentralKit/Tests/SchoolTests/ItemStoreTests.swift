import Data
import Domain
import Foundation
import School
import Testing

@MainActor struct ItemStoreTests {
    final class Changed: @unchecked Sendable {
        var students: Set<UUID> = []
    }

    func makeStore(
        _ id: UUID, items: [SchoolItem] = SchoolFixtures.boardItems, photos: FakePhotoStore = FakePhotoStore(),
        repo: FakeSchoolItemsRepository? = nil, online: Bool = true, changed: Changed = Changed()
    ) async -> ItemStore {
        let store = await ItemStore(
            itemID: id, workspace: FakeCentreRepository.meeraWorkspace,
            items: repo ?? FakeSchoolItemsRepository(items: items),
            register: SchoolFixtures.register(), schools: FakeSchoolsRepository(), photos: photos,
            now: { SchoolFixtures.now }, calendar: DayHeading.india, online: { online }
        )
        store.onChanged = { changed.students.formUnion($0) }
        return store
    }

    @Test func anExamsHeroWhoAndSourceLineReadFromTheItem() async throws {
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3)
        await store.load()
        #expect(store.state == .shown)
        let hero = try #require(store.hero)
        #expect(hero.eyebrow == "Vidya Niketan · Class 8 · Science" && hero.title == "Science unit test 3")
        #expect(hero.dateLine == "Friday 16 October · in 9 days")
        #expect(hero.portionsLine == "Portions: Ch 1 Chemical reactions · Ch 2 Acids, bases and salts")
        #expect(store.who.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        #expect(store.sourceLine == "Shared on Wed 7 Oct, 15:04" && store.coveredLine == nil)
    }

    @Test func aHolidaysPageSaysTheBatchDaysItCovers() async {
        let store = await makeStore(FakeSchoolItemsRepository.dasara)
        await store.load()
        let lines = store.coveredLine?.split(separator: "\n").map(String.init) ?? []
        #expect(lines.contains("Mon 19, Tue 20 and Wed 21 Oct · Evening batch"))
        #expect(lines.contains("Mon 19 and Wed 21 Oct · Class 10 Maths") && lines.count == 2)
        #expect(store.hero?.eyebrow == "Vidya Niketan · every class")
    }

    @Test func deleteRemovesTheItemAndItsPhotoAndTellsThePlan() async throws {
        var exam = try #require(SchoolFixtures.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 })
        exam.photoPath = "c/item/a.jpg"
        let photos = FakePhotoStore(paths: ["c/item/a.jpg"])
        let repo = FakeSchoolItemsRepository(items: [exam])
        let changed = Changed()
        let store = await makeStore(exam.id, photos: photos, repo: repo, changed: changed)
        await store.load()
        #expect(await store.delete())
        #expect(repo.stored.isEmpty && photos.paths.isEmpty && store.state == .gone)
        #expect(changed.students == [
            FakeStudentsRepository.dev,
            FakeStudentsRepository.meher,
            FakeStudentsRepository.nikhil,
        ])
    }

    @Test func anItemGoneReadsGone() async {
        let store = await makeStore(UUID())
        await store.load()
        #expect(store.state == .gone)
    }

    @Test func saveOfflineIsRefused() async throws {
        let store = await makeStore(FakeSchoolItemsRepository.mathsHomework, online: false)
        await store.load()
        var edited = try #require(store.item)
        edited.title = "Maths Ex 3.3"
        #expect(await store.save(edited) == false)
        #expect(store.message == OfflineRefusal.words(for: .schoolItem) && store.item?
            .title == "Maths Ex 3.2, Q1 to 10")
    }
}
