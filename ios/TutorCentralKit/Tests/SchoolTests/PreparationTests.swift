import Data
import Domain
import Foundation
import School
import Testing

/// An exam's Preparation (P10-School-Item; plan/phase-13-plan.md decision 22): one row per batch day from today to the
/// test, a tick for a day whose plan closed, Today, the Mock, the gap report's day; Test tomorrow from the day before.
@MainActor struct PreparationTests {
    static func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func makeStore(
        _ id: UUID, now: Date = SchoolFixtures.now, plans: FakePlansRepository = FakePlansRepository(),
        items: [SchoolItem] = SchoolFixtures.boardItems
    ) async -> ItemStore {
        await ItemStore(
            itemID: id, workspace: FakeCentreRepository.meeraWorkspace, items: FakeSchoolItemsRepository(items: items),
            register: SchoolFixtures.register(), schools: FakeSchoolsRepository(), photos: FakePhotoStore(),
            now: { now }, calendar: DayHeading.india, online: { true }, textbooks: FakeTextbooksRepository.evening(),
            plans: plans
        )
    }

    @Test func nineDaysOutShowsOneRowPerBatchDayToTheTest() async throws {
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3)
        await store.load()
        let rows = store.preparation
        #expect(rows.map(\.date) == ["7 Oct", "8 Oct", "9 Oct", "12 Oct", "13 Oct", "14 Oct", "15 Oct"])
        let first = try #require(rows.first)
        #expect(first.day == "Wed" && first.mark == .today && first.title.hasPrefix("Chemical reactions"))
        #expect(first.opens == .today(FakeClassesRepository.evening.id))
        let mock = try #require(rows.first { $0.date == "14 Oct" })
        #expect(mock.title == "The mock" && mock.mark == .mock)
        #expect(mock.line == "In the school's pattern · 40 marks · mark it from a photo")
        #expect(rows.last?.title == "What the mock showed" && rows.last?.line == "The last set from the gap report")
        #expect(rows.dropFirst().allSatisfy { $0.mark != .today })
        #expect(store.changeOpensToday == FakeClassesRepository.evening.id)
        #expect(!store.testTomorrowOffered && store.testTomorrowLine == nil)
    }

    @Test func aDayWhosePlanClosedIsDoneWithWhatWasMade() async throws {
        let plans = FakePlansRepository()
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let group = PlanGroup(
            number: 1, subject: "Science", chapter: "Science unit test 3", skill: "Chemical reactions",
            classLevels: [.eight], memberIDs: [FakeStudentsRepository.dev], skillID: nil,
            examItemID: FakeSchoolItemsRepository.scienceTest3
        )
        let line = PlanLine(
            studentID: FakeStudentsRepository.dev, groupNo: 1, kind: .practise, skillID: nil, words: "Revision set 1"
        )
        let draft = PlanDraft(
            classID: FakeClassesRepository.evening.id, date: FakeSchoolItemsRepository.day(7), groups: [group],
            lines: [line], leftOut: []
        )
        let plan = try await plans.make(draft, centre: centre)
        let sheet = SheetContent(
            title: "Set", instructions: nil,
            questions: (1 ... 6).map { SheetQuestion(number: $0, text: "q", answer: "a") },
            forHomework: false, light: false
        )
        _ = try await plans.keep(
            NewArtefact(
                kind: .sheet, source: .made, title: "Set", content: .sheet(sheet), photoPath: nil, generationID: nil,
                regeneratedFrom: nil
            ),
            to: ArtefactLink(plan: plan.id, group: 1, student: nil, itemKind: .practise), centre: centre
        )
        plans.markDone(Set(plan.items.map(\.id)), session: UUID())
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3, now: Self.at(7, 18, 40), plans: plans)
        await store.load()
        let today = try #require(store.preparation.first)
        #expect(today.mark == .done && today.line == "A set of 6 · done in today's class")
    }

    @Test func theDayBeforeOffersTestTomorrow() async {
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3, now: Self.at(15, 16, 35))
        await store.load()
        #expect(store.preparation.map(\.date) == ["15 Oct"])
        #expect(store.testTomorrowOffered)
        #expect(store.testTomorrowLine == "Test tomorrow goes to parents on Thursday evening")
        #expect(store.testTomorrowAsk?.student.id == FakeStudentsRepository.dev)
        #expect(store.testTomorrowAsk?.item.id == FakeSchoolItemsRepository.scienceTest3)
    }

    @Test func aHomeworkHasNoPreparation() async {
        let store = await makeStore(FakeSchoolItemsRepository.mathsHomework)
        await store.load()
        #expect(store.preparation.isEmpty && !store.testTomorrowOffered && store.changeOpensToday == nil)
    }

    @Test func anExamOutsideTheWindowShowsNoPreparationButTheDaysToGo() async throws {
        var items = SchoolFixtures.boardItems
        let index = try #require(items.firstIndex { $0.id == FakeSchoolItemsRepository.scienceTest3 })
        items[index].date = FakeSchoolItemsRepository.day(30)
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3, items: items)
        await store.load()
        #expect(store.preparation.isEmpty)
        #expect(store.hero?.dateLine == "Friday 30 October · in 23 days")
    }

    /// A portion no chapter of the student's matches stands as the title; the line does not repeat it.
    @Test func aPortionWithoutAChapterReadsASet() async throws {
        let store = await makeStore(FakeSchoolItemsRepository.scienceTest3)
        await store.load()
        let acids = try #require(store.preparation.first { $0.title.hasPrefix("Acids, bases and salts") })
        #expect(acids.line == "A set")
    }
}
