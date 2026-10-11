import Data
import Domain
import Foundation
import School
import Testing

@MainActor struct ReadStoreTests {
    let vidya = FakeSchoolsRepository.vidya.id
    let jpeg = ImageUpload(data: Data([0xFF, 0xD8, 0xFF, 0xE0]), mediaType: "image/jpeg")

    static func parsed(
        _ kind: SchoolItemKind, _ title: String, subject: String? = "Science", date: Day? = Day(
            year: 2026,
            month: 10,
            day: 14
        ),
        classLevel: ClassLevel? = nil, school: String? = nil, student: String? = nil
    ) -> ParsedItem {
        ParsedItem(
            kind: kind, title: title, subject: subject, date: date, endDate: nil, classLevel: classLevel,
            school: school,
            studentName: student, portions: nil
        )
    }

    final class Box: @unchecked Sendable {
        var left = 0
    }

    func makeStore(
        _ source: ReadSource, ai: FakeAIRepository = FakeAIRepository(), items: FakeSchoolItemsRepository? = nil,
        photos: FakePhotoStore = FakePhotoStore(), left: Box = Box(), online: Bool = true
    ) async -> ReadStore {
        await ReadStore(
            source: source, workspace: FakeCentreRepository.meeraWorkspace,
            items: items ?? FakeSchoolItemsRepository(items: []), ai: ai, register: SchoolFixtures.register(),
            schools: FakeSchoolsRepository(), photos: photos, leaveInbox: { left.left += 1 },
            now: { SchoolFixtures.now }, calendar: DayHeading.india, online: { online }
        )
    }

    @Test func aMessageReadsIntoThreeDraftsForTheRightPeople() async {
        let store = await makeStore(.pasted(SchoolFixtures.boardMessage))
        await store.read()
        #expect(store.stage == .read && store.drafts.count == 3 && store.countLine == "3 items read")
        #expect(store.drafts[0].audience == .schoolClass(school: vidya, level: .eight))
        #expect(store.drafts[2].kind == .holiday && store.drafts[2].audience == .school(vidya))
        #expect(store.drafts[2].endDate != nil && store.drafts[0].source == .pasted)
        #expect(store.drafts.allSatisfy(\.ticked) && store.addLabel == "Add 3 items")
    }

    @Test func aTimetablePhotoReadsIntoTwoExamsWithTheirDates() async {
        let store = await makeStore(.photo(jpeg))
        await store.read()
        #expect(store.drafts.map(\.kind) == [.exam, .exam] && store.drafts.map(\.date?.day) == [16, 16])
        #expect(store.drafts[0].source == .photo)
    }

    @Test func aDraftWithoutADateStaysUnticked() async {
        let ai = FakeAIRepository()
        ai.schoolItems = [Self.parsed(.exam, "Unit test", date: nil, classLevel: .eight, school: "Vidya Niketan")]
        let store = await makeStore(.pasted("Unit test next week"), ai: ai)
        await store.read()
        #expect(store.drafts[0].ticked == false && store.drafts[0].missing == [.date] && !store.canAdd)
    }

    @Test func settingTheDateOnTheSheetTicksTheDraft() async {
        let ai = FakeAIRepository()
        ai.schoolItems = [Self.parsed(.exam, "Unit test", date: nil, classLevel: .eight, school: "Vidya Niketan")]
        let store = await makeStore(.pasted("Unit test next week"), ai: ai)
        await store.read()
        var draft = store.drafts[0]
        draft.date = Day(year: 2026, month: 10, day: 14)
        store.replace(draft)
        #expect(store.drafts[0].ticked && store.canAdd && store.addLabel == "Add an item")
    }

    @Test func anItemForAnEmptyClassIsKeptAndSaysSo() async {
        let ai = FakeAIRepository()
        ai.schoolItems = [Self.parsed(.exam, "Class 9 unit test", classLevel: .nine, school: "Vidya Niketan")]
        let store = await makeStore(.pasted("Class 9 unit test"), ai: ai)
        await store.read()
        #expect(store.drafts[0].audience == .schoolClass(school: vidya, level: .nine) && store.drafts[0].ticked)
        #expect(await store.add())
    }

    @Test func aStudentNamedInTheMessageIsTheItemsAudienceAndAnUnknownNameLeavesItToChoose() async {
        let ai = FakeAIRepository()
        ai.schoolItems = [Self.parsed(.homework, "Science homework", student: "Dev Kumar")]
        let dev = await makeStore(.pasted("Dev Kumar has not submitted his science homework."), ai: ai)
        await dev.read()
        #expect(dev.drafts[0].audience == .student(FakeStudentsRepository.dev))
        let other = FakeAIRepository()
        other.schoolItems = [Self.parsed(.homework, "Science homework", student: "Rahul Verma")]
        let unknown = await makeStore(.pasted("Rahul has …"), ai: other)
        await unknown.read()
        #expect(unknown.drafts[0].audience == nil && unknown.drafts[0].missing == [.audience])
        #expect(!unknown.drafts[0].ticked)
    }

    @Test func addWritesTheTickedCompleteDraftsUploadsThePhotoAndLeavesTheInbox() async {
        let items = FakeSchoolItemsRepository(items: [])
        let photos = FakePhotoStore()
        let left = Box()
        let shared = SharedRead(id: "a", text: nil, image: jpeg, receivedAt: SchoolFixtures.now)
        let store = await makeStore(.shared(shared), items: items, photos: photos, left: left)
        await store.read()
        #expect(store.drafts.first?.source == .sharedPhoto)
        store.toggle(store.drafts[1].id)
        #expect(await store.add())
        #expect(items.stored.count == 1 && items.stored[0].photoPath?.contains("/item/") == true)
        #expect(photos.paths.count == 1 && left.left == 1)
    }

    @Test func aSharedItemKeepsTheTimeItWasShared() async {
        let items = FakeSchoolItemsRepository(items: [])
        let sharedAt = SchoolFixtures.now.addingTimeInterval(-180)
        let shared = SharedRead(id: "a", text: SchoolFixtures.boardMessage, image: nil, receivedAt: sharedAt)
        let store = await makeStore(.shared(shared), items: items)
        await store.read()
        #expect(store.drafts.allSatisfy { $0.receivedAt == sharedAt })
        #expect(await store.add())
        #expect(items.stored.allSatisfy { $0.receivedAt == sharedAt })
    }

    @Test func nothingReadIsSaidInWordsAndOfflineTheInboxWaits() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.refused("Couldn't find a test, homework, notice or holiday in this. Add it by hand."))
        let none = await makeStore(.pasted("Good morning"), ai: ai)
        await none.read()
        #expect(none.stage == .failed("Couldn't find a test, homework, notice or holiday in this. Add it by hand."))
        let left = Box()
        let offline = await makeStore(.pasted("x"), left: left, online: false)
        await offline.read()
        #expect(offline.message == OfflineRefusal.words(for: .readPasted) && left.left == 0)
    }

    @Test func addOfflineIsRefusedAndKeepsTheDrafts() async {
        let store = await makeStore(.pasted(SchoolFixtures.boardMessage))
        await store.read()
        store.online = { false }
        #expect(await store.add() == false)
        #expect(store.message == OfflineRefusal.words(for: .schoolItem) && store.drafts.count == 3)
    }

    @Test func leavingRemovesTheInboxItemAndByHandStartsWithNothing() async {
        let left = Box()
        let store = await makeStore(.typed, left: left)
        await store.read()
        #expect(store.stage == .read && store.drafts.isEmpty && !store.canAdd)
        store.leave()
        #expect(left.left == 1)
    }

    @Test func pasteAMessageWaitsForThePasteButtonAndReadsOnIt() async {
        let ai = FakeAIRepository()
        let store = await makeStore(.pasteWaiting, ai: ai)
        await store.read()
        #expect(store.stage == .pasteWaiting && ai.parseCalls.isEmpty && !store.canAdd)
        #expect(store
            .pasteLine == "Copy the school's message in WhatsApp, then tap Paste. Nothing is read until you do.")
        await store.paste(SchoolFixtures.boardMessage)
        #expect(ai.parseCalls.count == 1 && store.drafts.count == 3 && store.sourceText == SchoolFixtures.boardMessage)
    }

    @Test func pastingNothingSaysSoAndKeepsWaiting() async {
        let ai = FakeAIRepository()
        let store = await makeStore(.pasteWaiting, ai: ai)
        await store.read()
        await store.paste("   ")
        #expect(store.stage == .pasteWaiting && ai.parseCalls.isEmpty && store.message != nil)
    }

    @Test func aFailedAddRemovesTheUploadedPhoto() async {
        let photos = FakePhotoStore()
        let items = FakeSchoolItemsRepository(items: [])
        let store = await makeStore(.photo(jpeg), items: items, photos: photos)
        await store.read()
        #expect(store.canAdd)
        items.nextError = URLError(.badServerResponse)
        #expect(await store.add() == false)
        #expect(photos.paths.isEmpty)
        #expect(store.stage == .read && !store.drafts.isEmpty)
    }

    @Test func theOfflineRefusalNamesTheSource() async {
        let shared = SharedRead(id: "a", text: SchoolFixtures.boardMessage, image: nil, receivedAt: SchoolFixtures.now)
        for (source, refusal) in [
            (ReadSource.shared(shared), OfflineRefusal.Write.readShared),
            (.pasted(SchoolFixtures.boardMessage), .readPasted), (.photo(jpeg), .readPhoto),
        ] {
            let store = await makeStore(source, online: false)
            await store.read()
            #expect(store.message == OfflineRefusal.words(for: refusal))
        }
    }
}
