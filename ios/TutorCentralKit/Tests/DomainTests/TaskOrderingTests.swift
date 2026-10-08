import Foundation
import Testing
@testable import Domain

struct TaskOrderingTests {
    static let calendar = DayHeading.india
    static func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    static func task(_ title: String, due: Int? = nil, doneAt: Date? = nil, created: Date = at(1, 9)) -> TaskItem {
        TaskItem(
            id: UUID(),
            title: title,
            dueDate: due.flatMap { Day(year: 2026, month: 10, day: $0) },
            doneAt: doneAt,
            createdAt: created
        )
    }

    @Test func openByDueDateThenCreation() {
        let tasks = [
            Self.task("No date", created: Self.at(2, 9)),
            Self.task("Chalk", created: Self.at(1, 9)),
            Self.task("Call", due: 9),
            Self.task("Print", due: 8),
        ]
        #expect(TaskOrdering.open(tasks).map(\.title) == ["Print", "Call", "Chalk", "No date"])
    }

    @Test func doneTasksStayADay() {
        let now = Self.at(8, 10)
        let justDone = Self.task("Workbooks", doneAt: Self.at(7, 23, 30))
        let oldDone = Self.task("Report", doneAt: Self.at(7, 9))
        let open = Self.task("Chalk")
        #expect(
            TaskOrdering.onToday([oldDone, justDone, open], now: now).map(\.title) == ["Chalk", "Workbooks"],
            "done at 23:30 stays past midnight; done 25 h ago is gone"
        )
        #expect(TaskOrdering.done([oldDone, justDone]).map(\.title) == ["Workbooks", "Report"])
    }

    static func due(_ task: TaskItem, today: Day) -> String? {
        TaskOrdering.dueText(task, today: today, calendar: calendar).map { "\($0.text)\($0.overdue ? " overdue" : "")" }
    }

    @Test func dueWordsAndOverdue() throws {
        let today = try #require(Day(year: 2026, month: 10, day: 7))
        #expect(Self.due(Self.task("A", due: 7), today: today) == "Today")
        #expect(Self.due(Self.task("B", due: 8), today: today) == "Tomorrow")
        #expect(Self.due(Self.task("C", due: 9), today: today) == "Fri 9 Oct")
        #expect(Self.due(Self.task("D", due: 5), today: today) == "Mon 5 Oct overdue")
        #expect(TaskOrdering.dueText(Self.task("E"), today: today, calendar: Self.calendar) == nil)
        #expect(
            TaskOrdering
                .dueText(Self.task("F", due: 5, doneAt: Self.at(6, 9)), today: today, calendar: Self.calendar) == nil,
            "done: the done day shows instead"
        )
        #expect(TaskOrdering.doneText(Self.task("F", doneAt: Self.at(6, 9)), calendar: Self.calendar) == "Tue 6 Oct")
    }
}
