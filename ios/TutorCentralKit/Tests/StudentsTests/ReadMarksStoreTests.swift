import Data
import Domain
import Foundation
import Testing
@testable import Students

/// Marks from a photo (P14-Marks-Reading, -Confirm, -Edit; plan/phase-14-plan.md Task 17): a report card or a marked
/// test read into rows, checked and dated, saved, undone.
@MainActor struct ReadMarksStoreTests {
    nonisolated static let friday = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 9,
        hour: 16,
        minute: 35
    ))!
    static let hemanth = FakeStudentsRepository.hemanth
    static let riya = FakeStudentsRepository.riya
    static let page = ImageUpload(data: Data(repeating: 7, count: 2000), mediaType: "image/jpeg")

    final class Online {
        var now = true
    }

    @MainActor struct World {
        var ai = FakeAIRepository()
        var record = FakeRecordRepository(checks: [], homework: [], marks: [])
        var online = Online()
    }

    static func students() -> [Student] {
        FakeStudentsRepository.seed.map { student in
            var changed = student
            if student.id != riya, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: friday, phone: phone, how: .inPerson)
            }
            return changed
        }
    }

    static func register() async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students()),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { friday }
        )
        await register.loadIfNeeded()
        return register
    }

    static func store(_ world: World, _ id: UUID = hemanth) async -> ReadMarksStore {
        let online = world.online
        return await ReadMarksStore(
            student: id, register: register(), textbooks: FakeTextbooksRepository.seeded(), ai: world.ai,
            record: world.record, online: { online.now }, now: { friday }
        )
    }

    @Test func aReportCardReadsIntoRowsWithTheUndatedOneUnticked() async {
        let world = World()
        let store = await Self.store(world)
        #expect(store.heroName == "Hemanth Reddy" && store.heroLine == "From a photo · a report card or a marked test")
        store.add(Self.page)
        await store.read()
        #expect(store.stage == .read && store.rows.count == 3)
        #expect(store.rows[0].title == "Mathematics · Unit test 2" && store.rows[0].line == "28 Sep")
        #expect(store.rows[0].score == "14 of 25" && store.rows[0].ticked)
        #expect(store.rows[2].title == "Hindi · Unit test 2" && store.rows[2].line == "Date · not given")
        #expect(store.rows[2].lineIsMissing && !store.rows[2].ticked)
        #expect(store.saveLabel == "Save 2 marks" && store.canSave && store.title == "3 marks read")
        #expect(world.ai.readMarksCalls.first?.subjects.first == "Mathematics")
        #expect(world.ai.readMarksCalls.first?.pages.count == 1)
    }

    @Test func settingTheDateOnTheSheetTicksTheRow() async {
        let store = await Self.store(World())
        store.add(Self.page)
        await store.read()
        var mark = store.rows[2].mark
        mark.date = Day(year: 2026, month: 9, day: 29)
        store.edit(store.rows[2].id, mark)
        #expect(store.rows[2].ticked && store.rows[2].line == "29 Sep" && store.saveLabel == "Save 3 marks")
    }

    @Test func aRowUntickedByHandStaysOutAndARemovedRowGoes() async {
        let store = await Self.store(World())
        store.add(Self.page)
        await store.read()
        store.toggle(store.rows[0].id)
        #expect(store.saveLabel == "Save 1 mark")
        store.toggle(store.rows[2].id)
        #expect(!store.rows[2].ticked)
        store.remove(store.rows[1].id)
        #expect(store.rows.count == 2 && !store.canSave && store.saveLabel == "Save")
    }

    @Test func saveWritesATickedRowEachAndTheToastUndoesThem() async {
        let world = World()
        let store = await Self.store(world)
        store.add(Self.page)
        await store.read()
        #expect(await store.save())
        let added = world.record.marks
        #expect(added.count == 2 && added.allSatisfy { $0.photoPath == nil && $0.schoolItemID == nil })
        #expect(added[0].subject == "Mathematics" && added[0].test == "Unit test 2")
        #expect(added[0].score == 14 && added[0].max == 25 && added[0].studentID == Self.hemanth)
        #expect(store.toast == "2 marks saved to Hemanth's page")
        #expect(await store.undo() && world.record.marks.isEmpty)
    }

    @Test func aSubjectWithNoBookIsKeptAsWrittenAndSaved() async {
        let world = World()
        world.ai.readMarksRows = [
            ReadMark(
                subject: "Social science", test: "Unit test 2", date: Day(year: 2026, month: 9, day: 30), score: 17,
                max: 25
            ),
        ]
        let store = await Self.store(world)
        store.add(Self.page)
        await store.read()
        #expect(await store.save() && world.record.marks.first?.subject == "Social science")
    }

    @Test func aThirdPageIsRefusedAndTwoAreSent() async {
        let world = World()
        let store = await Self.store(world)
        store.add(Self.page)
        store.add(Self.page)
        store.add(Self.page)
        #expect(store.pages.count == 2)
        #expect(store.message == "Two pages at most. A report card is one; a marked test front and back is two.")
        await store.read()
        #expect(world.ai.readMarksCalls.first?.pages.count == 2)
    }

    @Test func aPageAddedWhileReadingReadsBothPagesAgain() async throws {
        let world = World()
        world.ai.delayByKind[.readMarks] = .milliseconds(300)
        let store = await Self.store(world)
        store.add(Self.page)
        store.begin()
        try await Task.sleep(for: .milliseconds(50))
        #expect(store.canAddPage)
        store.addAndRead(Self.page)
        while store.stage != .read {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(world.ai.readMarksCalls.last?.pages.count == 2 && store.rows.count == 3)
    }

    @Test func cancelStopsTheReadThatWasStartedOver() async throws {
        let world = World()
        world.ai.delayByKind[.readMarks] = .milliseconds(300)
        let store = await Self.store(world)
        store.add(Self.page)
        store.begin()
        try await Task.sleep(for: .milliseconds(50))
        store.addAndRead(Self.page)
        try await Task.sleep(for: .milliseconds(50))
        store.cancel()
        try await Task.sleep(for: .milliseconds(450))
        #expect(store.stage == .choosing && store.rows.isEmpty)
    }

    @Test func noMarksReadIsSaidInWordsAndTheRowsStayEmpty() async {
        let world = World()
        world.ai.scriptByKind[.readMarks] = .failure(
            .refused("Couldn't read any marks from this photo. Try a flatter, brighter one.")
        )
        let store = await Self.store(world)
        store.add(Self.page)
        await store.read()
        #expect(store.stage == .failed("Couldn't read any marks from this photo. Try a flatter, brighter one."))
        #expect(store.rows.isEmpty)
    }

    @Test func anEmptyAnswerIsSaidInWords() async {
        let world = World()
        world.ai.readMarksRows = []
        let store = await Self.store(world)
        store.add(Self.page)
        await store.read()
        #expect(store.stage == .failed("Couldn't read any marks from this photo. Try a flatter, brighter one."))
    }

    @Test func withoutConsentTheActionIsDisabledWithTheReasonAndNoCallIsMade() async {
        let world = World()
        let store = await Self.store(world, Self.riya)
        #expect(store.consentLine == "Marks from a photo wait for Neha's consent.")
        store.add(Self.page)
        await store.read()
        #expect(world.ai.readMarksCalls.isEmpty && store
            .stage == .failed("Marks from a photo wait for Neha's consent."))
    }

    @Test func offlineReadingAndSavingAreRefusedInWordsAndTheRowsStay() async {
        let world = World()
        world.online.now = false
        let store = await Self.store(world)
        store.add(Self.page)
        await store.read()
        #expect(store.stage == .failed(OfflineRefusal.words(for: .readMarks)))
        let later = World()
        let saved = await Self.store(later)
        saved.add(Self.page)
        await saved.read()
        later.online.now = false
        #expect(await saved.save() == false && saved.message == OfflineRefusal.words(for: .saveMarks))
        #expect(saved.rows.count == 3 && later.record.marks.isEmpty)
    }

    @Test func thePageOffersAddFromAPhotoOnlyWithConsent() async {
        let register = await Self.register()
        let page = { (id: UUID) in
            StudentDetailStore(
                id: id, register: register, attendance: FakeAttendanceRepository(sessions: []),
                messages: FakeMessageLogRepository(), textbooks: FakeTextbooksRepository.seeded(),
                record: FakeRecordRepository(checks: [], homework: []), now: { Self.friday }, online: { true }
            )
        }
        let hemanth = page(Self.hemanth)
        #expect(hemanth.canAddMarks && hemanth.marksConsentLine == nil)
        let riya = page(Self.riya)
        #expect(!riya.canAddMarks && riya.marksConsentLine == "Marks from a photo wait for Neha's consent.")
    }
}
