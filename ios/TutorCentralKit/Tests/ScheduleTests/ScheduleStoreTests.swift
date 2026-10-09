import Data
import Domain
import Foundation
import Students
import Testing
@testable import Schedule

@MainActor struct ScheduleStoreTests {
    let events = FakeEventsRepository(events: FakeEventsRepository.seed)

    func make() async -> ScheduleStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = ScheduleStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, events: events,
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func octoberWithTodayChosen() async throws {
        let store = await make()
        #expect(store.monthTitle == "October 2026" && store.selected == store.today && store
            .dayTitle == "Today, 7 October")
        #expect(try store.markedDays.contains(#require(Day(year: 2026, month: 10, day: 10))) && store.markedDays
            .contains(#require(Day(
                year: 2026,
                month: 10,
                day: 8
            ))))
        #expect(try !store.markedDays.contains(#require(Day(year: 2026, month: 10, day: 11))), "a Sunday with nothing")
        #expect(store.classRows.map(\.classroom.name) == ["Class 10 Maths"] && store.classRows[0]
            .line == "5 of 6 present" && store.classRows[0].marked)
        #expect(store.classRows[0].start == "17:00" && store.classRows[0].end == "18:00")
        #expect(store.comingUp.map(\.day) == ["Sat 10", "Sat 17"] && store.comingUp[0]
            .line == "11:00–12:00 · Class 10 parents")
        #expect(store.eventRows.isEmpty && store.noClassLine == nil)
    }

    @Test func aSaturdayWithAnEventAndNoClass() async throws {
        let store = await make()
        try await store.select(#require(Day(year: 2026, month: 10, day: 10)))
        #expect(store.dayTitle == "Saturday 10 October" && store.classRows.isEmpty && store
            .noClassLine == "No classes meet on Saturdays.")
        #expect(store.eventRows.map(\.event.title) == ["Parents' meeting"] && store.eventRows[0]
            .start == "11:00" && store.eventRows[0].line == "Class 10 parents. Bring the September test papers.")
        #expect(store.comingUp.isEmpty, "coming up shows only with today chosen")
    }

    @Test func anUnmarkedClassShowsItsSummary() async throws {
        let store = await make()
        try await store.select(#require(Day(year: 2026, month: 10, day: 8)))
        #expect(store.classRows[0].classroom.name == "Class 8 Science" && store.classRows[0]
            .line == "Tue, Thu · 3 students" && !store.classRows[0].marked)
    }

    @Test func addEditDeleteWithRollback() async throws {
        let store = await make()
        var draft = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 20)))
        draft.title = "Holiday"
        let made = try #require(await store.add(draft))
        #expect(store.events.contains { $0.id == made.id } && store.markedDays.contains(made.date) && store
            .lastSavedAt != nil)
        draft.title = "Diwali holiday"
        #expect(await store.update(made.id, with: draft) && store.events.first { $0.id == made.id }?
            .title == "Diwali holiday")
        events.nextError = URLError(.badServerResponse)
        draft.title = "Lost"
        #expect(await store.update(made.id, with: draft) == false)
        #expect(store.events.first { $0.id == made.id }?.title == "Diwali holiday" && store
            .message == "Couldn't save the event. Check your connection and try again." && store.canRetry)
        #expect(await store.delete(made.id) && !store.events.contains { $0.id == made.id })
        events.nextError = URLError(.badServerResponse)
        #expect(
            await store.delete(FakeEventsRepository.mockTest.id) == false && store.events.count == 2,
            "a delete waits for the server"
        )
    }

    @Test func theMonthsMove() async {
        let store = await make()
        await store.nextMonth()
        #expect(store.monthTitle == "November 2026" && store.selected == Day(year: 2026, month: 11, day: 1) && store
            .events.isEmpty)
        await store.previousMonth()
        #expect(
            store.monthTitle == "October 2026" && store.selected == store.today,
            "back in today's month, today is chosen again"
        )
    }

    @Test func aQuickSecondMonthMoveWins() async {
        // Review, Important: November's events read is slow; a quick move back to October must show October.
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        let store = ScheduleStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register,
            events: SlowNovemberEvents(events: FakeEventsRepository.seed),
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday),
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        async let ahead: Void = store.nextMonth()
        try? await Task.sleep(for: .milliseconds(10))
        await store.previousMonth()
        await ahead
        #expect(store.monthTitle == "October 2026" && store.events.count == 2)
    }

    /// The shell plans the reminders again after a saved event; not after a failed one.
    @Test func aSavedEventIsToldAndAFailedOneIsNot() async throws {
        let store = await make()
        var told = 0
        store.onEventsChanged = { told += 1 }
        var draft = try EventDraft(date: #require(Day(year: 2026, month: 10, day: 20)))
        draft.title = "Holiday"
        _ = await store.add(draft)
        events.nextError = URLError(.badServerResponse)
        _ = await store.add(draft)
        #expect(told == 1)
    }
}

/// Events whose read of a range starting in November is slow, so two month moves finish in the other order.
@MainActor final class SlowNovemberEvents: EventsRepository {
    let fake: FakeEventsRepository

    init(events: [CalendarEvent]) {
        fake = FakeEventsRepository(events: events)
    }

    func events(centre: UUID, from: Day, to: Day) async throws -> [CalendarEvent] {
        if from.month == 11 {
            try await Task.sleep(for: .milliseconds(150))
            return []
        }
        return try await fake.events(centre: centre, from: from, to: to)
    }

    func create(_ draft: EventDraft, centre: UUID) async throws -> CalendarEvent {
        try await fake.create(draft, centre: centre)
    }

    func update(id: UUID, with draft: EventDraft) async throws -> CalendarEvent {
        try await fake.update(id: id, with: draft)
    }

    func delete(id: UUID) async throws {
        try await fake.delete(id: id)
    }
}
