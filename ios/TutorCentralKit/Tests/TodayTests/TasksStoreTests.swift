import Data
import Domain
import Foundation
import Testing
@testable import Today

@MainActor struct TasksStoreTests {
    let repo = FakeTasksRepository(tasks: FakeTasksRepository.seed)

    func make() async -> TasksStore {
        let store = TasksStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            tasks: repo,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    /// The trailing words with "overdue" when they are in that tone.
    func trail(_ store: TasksStore, _ task: TaskItem) -> String? {
        store.trailing(for: task).map { "\($0.text)\($0.tone == .overdue ? " overdue" : "")" }
    }

    @Test func theListsAsTheBoardsDrawThem() async {
        let store = await make()
        #expect(store.open.map(\.title) == ["Call Dev's father about Saturday", "Buy chalk and dusters"])
        #expect(store.openTitle == "2 to do")
        #expect(store.done.map(\.title) == ["Order Class 8 workbooks", "Send September report to parents"])
        #expect(
            store.onToday.map(\.title) == ["Call Dev's father about Saturday", "Buy chalk and dusters"],
            "done on the 6th and 1st: off Today by the 7th"
        )
        #expect(trail(store, store.open[0]) == "Fri 9 Oct" && trail(store, store.open[1]) == nil)
        #expect(trail(store, store.done[0]) == "Tue 6 Oct")
        #expect(store.dueChips.map(\.label) == ["Tomorrow", "No date"], "Wednesday's next weekday is Thursday")
    }

    @Test func aChosenDayNamesTheDateChip() async {
        let store = await make()
        store.newDue = Day(year: 2026, month: 10, day: 9)
        #expect(store.dueChips.map(\.label) == ["Fri 9 Oct", "No date"] && store.dueChips[0].day == store.newDue)
    }

    @Test func addingIsOptimisticAndRollsBack() async {
        let store = await make()
        store.adding = true
        store.newTitle = "  Print worksheets for Class 8 "
        store.newDue = Day(year: 2026, month: 10, day: 9)
        #expect(store.canAdd)
        #expect(await store.add())
        #expect(store.open.map(\.title) == [
            "Call Dev's father about Saturday", "Print worksheets for Class 8", "Buy chalk and dusters",
        ], "due Fri 9 Oct, after the older task due that day, before the undated one")
        #expect(repo.created.count == 1 && !store.adding && store.newTitle.isEmpty)
        store.adding = true
        store.newTitle = "Lost one"
        repo.nextError = URLError(.notConnectedToInternet)
        #expect(await store.add() == false)
        #expect(!store.open.contains { $0.title == "Lost one" } && store
            .message == "Couldn't add the task. Check your connection and try again." && store.canRetry)
        #expect(store.newTitle == "Lost one" && store.adding, "the typing stays")
        await store.retryLast()
        #expect(store.open.contains { $0.title == "Lost one" } && repo.created.count == 2)
    }

    @Test func doneAndClear() async throws {
        let store = await make()
        let chalk = store.open[1]
        await store.setDone(chalk.id, true)
        #expect(
            store.done.first?.id == chalk.id && store.onToday.last?.id == chalk.id,
            "just done: still on Today, at the end"
        )
        await store.setDone(chalk.id, false)
        #expect(store.open.contains { $0.id == chalk.id })
        await store.clearDone()
        #expect(store.done.isEmpty && repo.cleared == 1 && store.tasks.count == 2)
        repo.nextError = URLError(.notConnectedToInternet)
        await store.setDone(chalk.id, true)
        #expect(try #require(store.open.first { $0.id == chalk.id }).isDone == false)
        #expect(store.message == "Couldn't update the task. Check your connection and try again.")
    }

    @Test func overdueReadsInTheOverdueTone() async {
        let store = await make()
        store.newTitle = "Late"
        store.newDue = Day(year: 2026, month: 10, day: 5)
        _ = await store.add()
        #expect(store.open.first?.title == "Late" && trail(store, store.open[0]) == "Mon 5 Oct overdue")
    }

    @Test func aTapOnTheDateChipTurnsItOnWithTheSuggestedDay() async {
        // The picker opens with the suggested day already chosen; picking it again changes nothing, so the tap does.
        let store = await make()
        store.pickDueChip()
        #expect(store.newDue == Day(year: 2026, month: 10, day: 8) && store.dueChips[0].label == "Tomorrow")
        store.newDue = Day(year: 2026, month: 10, day: 9)
        store.pickDueChip()
        #expect(store.newDue == Day(year: 2026, month: 10, day: 9), "a chosen day stays")
    }
}
