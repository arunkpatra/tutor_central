import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// To parents after the close (P10-Today-AfterClose; plan/phase-13-plan.md decisions 20 and 21).
@MainActor struct ToParentsTests {
    let devsTest = FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.devsTest }!
    let exam16 = FakeSchoolItemsRepository.boardItems.first { $0.id == FakeSchoolItemsRepository.scienceTest3 }!

    /// Dev's parent writes in Hindi (the board's).
    var students: [Student] {
        FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            if student.id == FakeStudentsRepository.dev {
                changed.messageLanguage = .hindi
            }
            return changed
        }
    }

    func entry(_ kind: MessageKind, at date: Date) -> MessageEntry {
        MessageEntry(id: UUID(), kind: kind, openedAt: date, language: nil)
    }

    func makeStore(
        items: [SchoolItem], closed: Bool, absent: Set<UUID> = [], messages: FakeMessageLogRepository? = nil
    ) async -> TodayStore {
        let now = PlanTest.at1840
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        let members = students.filter { $0.classID == FakeClassesRepository.evening.id }
        let marks = Dictionary(uniqueKeysWithValues: members.map {
            ($0.id, absent.contains($0.id) ? AttendanceStatus.absent : .present)
        })
        let session = AttendanceSession(
            id: UUID(), classID: FakeClassesRepository.evening.id, date: PlanTest.wednesday, savedAt: now, marks: marks,
            closedAt: closed ? now : nil
        )
        let store = TodayStore(
            workspace: FakeCentreRepository.meeraWorkspace, counts: FakeCountsRepository(), register: register,
            attendance: FakeAttendanceRepository(sessions: [session]), events: FakeEventsRepository(events: []),
            tasks: TasksStore(
                workspace: FakeCentreRepository.meeraWorkspace,
                tasks: FakeTasksRepository(),
                now: { now }
            ),
            now: { now }
        )
        store.schoolItems = FakeSchoolItemsRepository(items: items)
        store.messages = messages ?? FakeMessageLogRepository(now: { now })
        return store
    }

    @Test func tomorrowIsSuggestedTheEveningBefore() async {
        let store = await makeStore(items: [devsTest], closed: true)
        await store.load()
        #expect(store.toParents.map(\.title) == ["Test tomorrow"])
        #expect(store.toParents.first?
            .detail == "Dev's parent · Hindi · Science unit test on Thu 8 Oct, chapters 1 and 2")
        #expect(store.toParents.first?.state == .send)
    }

    @Test func anAbsentStudentWithANumberMakesAnAbsentTodayRow() async {
        let store = await makeStore(items: [], closed: true, absent: [FakeStudentsRepository.nikhil])
        await store.load()
        #expect(store.toParents.map(\.title) == ["Absent today"])
        #expect(store.toParents.first?.detail == "Nikhil's parent · English · the absence alert")
    }

    @Test func noRowsBeforeTheCloseAndNoneForAnExamInTwoDays() async {
        let open = await makeStore(items: [devsTest], closed: false)
        await open.load()
        #expect(open.toParents.isEmpty)
        let later = await makeStore(items: [exam16], closed: true)
        await later.load()
        #expect(later.toParents.isEmpty)
    }

    @Test func theCadenceHoldsAFourthSuggestionAndNeverAHandSend() async {
        let monday = PlanTest.at(5, 18, 0)
        let three = FakeMessageLogRepository(entries: [
            FakeStudentsRepository.dev: [entry(.note, at: monday), entry(.canDo, at: monday), entry(.note, at: monday)],
        ])
        let held = await makeStore(items: [devsTest], closed: true, messages: three)
        await held.load()
        #expect(held.toParents.isEmpty)
        let hand = FakeMessageLogRepository(entries: [
            FakeStudentsRepository.dev: [
                entry(.reminder, at: monday),
                entry(.absence, at: monday),
                entry(.consent, at: monday),
            ],
        ])
        let open = await makeStore(items: [devsTest], closed: true, messages: hand)
        await open.load()
        #expect(open.toParents.count == 1)
    }

    @Test func aSentRowReadsSent() async {
        let sent = FakeMessageLogRepository(entries: [
            FakeStudentsRepository.dev: [entry(.testTomorrow, at: PlanTest.at(7, 18, 39))],
        ])
        let store = await makeStore(items: [devsTest], closed: true, messages: sent)
        await store.load()
        #expect(store.toParents.first?.state == .sent)
    }
}
