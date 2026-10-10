import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// The close (P10-Close, -Scrolled, -Placement): attendance, three checks per student or the placement, homework, Done.
@MainActor struct CloseStoreTests {
    nonisolated static let fivepast = at(7, 17, 5)

    nonisolated static func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func register(evening: Bool = true) async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(
                students: evening ? FakeStudentsRepository.eveningSeed : FakeStudentsRepository.seed
            ),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { Self.fivepast }
        )
        await register.load()
        return register
    }

    func store(
        classID: UUID = FakeClassesRepository.evening.id,
        ai: FakeAIRepository = FakeAIRepository(),
        attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
        record: FakeRecordRepository = FakeRecordRepository(),
        textbooks: FakeTextbooksRepository = .evening(),
        now: Date = fivepast
    ) async -> CloseStore {
        let register = await register(evening: classID == FakeClassesRepository.evening.id)
        let store = CloseStore(
            classID: classID, workspace: FakeCentreRepository.meeraWorkspace, register: register,
            textbooks: textbooks, record: record, attendance: attendance, ai: ai, now: { now }
        )
        await store.load()
        return store
    }

    func index(_ store: CloseStore, _ name: String) -> Int {
        store.students.firstIndex { $0.name == name } ?? -1
    }

    @Test func everyoneStartsPresentWithHomeworkGivenAndThreeChecksFromTheQueue() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai)
        #expect(store.title == "Close the class")
        #expect(store.batchLine == "Wednesday 7 October · 17:00–18:30 · 5 students")
        #expect(store.students.count == 5 && store.students.allSatisfy { $0.present && $0.homeworkGiven })
        let dev = store.students[index(store, "Dev Kumar")]
        guard case let .rows(rows) = dev.checks else { Issue.record("no rows")
            return
        }
        #expect(rows.map(\.skill) == ["Types of reactions", "Chemical change", "Balancing equations"])
        #expect(ai.checkCalls.contains(rows.map(\.skill)))
    }

    @Test func aStudentWithNothingTaughtGetsThePlacementAndOneWithNoChaptersHasAttendanceAndHomeworkOnly() async {
        let store = await store()
        guard case let .placement(subjects) = store.students[index(store, "Riya Sharma")].checks else {
            Issue.record("Riya should be placed")
            return
        }
        #expect(subjects.map(\.title) == ["Mathematics"] && subjects[0].rows.count == 5)
        let nikhil = store.students[index(store, "Nikhil Das")]
        #expect(nikhil.checks == .none && nikhil.homeworkGiven)
        guard case .rows = store.students[index(store, "Sahil Verma")].checks else { Issue.record("ladder")
            return
        }
    }

    @Test func doneWithNothingTappedClosesWithAttendanceAlone() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await store(attendance: attendance)
        #expect(await store.done())
        let close = attendance.closes[0]
        #expect(close.checks.isEmpty && close.states.isEmpty && close.homework.count == 5)
        #expect(close.marks.values.allSatisfy { $0 == .present } && close.classID == FakeClassesRepository.evening.id)
        #expect(close.track.count == 5)
        #expect(store.phase == .closed(at: Self.fivepast))
    }

    @Test func tapsBecomeChecksStatesAndStatusesAndAnAbsentStudentsTapsAreDropped() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await store(attendance: attendance)
        let dev = index(store, "Dev Kumar"), meher = index(store, "Meher Shah")
        store.tap(dev, 0, right: true)
        store.tap(dev, 1, right: false)
        store.tap(meher, 0, right: true)
        store.toggle(meher)
        store.setHomework(dev, given: false)
        #expect(store.summary == "4 of 5 came, 1 check right")
        #expect(await store.done())
        let close = attendance.closes[0]
        #expect(close.checks.count == 2 && close.checks.allSatisfy { $0.studentID == store.students[dev].id })
        #expect(close.homework.count == 3)
        let types = FakeTextbooksRepository.evening().skillsByStudent[FakeStudentsRepository.dev]?
            .first { $0.name == "Types of reactions" }
        #expect(close.states.contains { $0.skillID == types?.id && $0.state == .practising })
        #expect(close.marks[store.students[meher].id] == .absent)
    }

    @Test func thePlacementsTapsAreKeptAsPlacementChecksAndSecureTheChaptersBefore() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await store(attendance: attendance)
        let riya = index(store, "Riya Sharma")
        store.tapPlacement(riya, subject: 0, row: 0, right: true)
        store.tapPlacement(riya, subject: 0, row: 1, right: false)
        #expect(await store.done())
        let close = attendance.closes[0]
        #expect(close.checks.count == 2 && close.checks.allSatisfy(\.isPlacement))
        let firstChapter = FakeTextbooksRepository.evening().skillsByStudent[FakeStudentsRepository.riya]?
            .filter { $0.chapterID == FakeTextbooksRepository.evening().chaptersByStudent[FakeStudentsRepository.riya]?
                .first?.id
            }
        #expect(Set(close.states.map(\.skillID)) == Set(firstChapter?.map(\.id) ?? []))
    }

    @Test func aFailedCheckCallShowsInPlaceAndDoneStillWorks() async {
        let ai = FakeAIRepository()
        ai.scriptBySubject = ["Science": .failure(.service)]
        let store = await store(ai: ai)
        #expect(store.students[index(store, "Dev Kumar")].checks == .failed("The AI service didn't answer. Try again."))
        #expect(await store.done())
    }

    @Test func tryAgainMakesTheChecks() async {
        let ai = FakeAIRepository()
        ai.scriptBySubject = ["Science": .failure(.service)]
        let store = await store(ai: ai)
        ai.scriptBySubject = [:]
        await store.retryChecks(for: index(store, "Dev Kumar"))
        guard case .rows = store.students[index(store, "Dev Kumar")].checks else { Issue.record("rows")
            return
        }
    }

    @Test func reopeningTodaysCloseShowsItsTaps() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithTodayClosed)
        let record = FakeRecordRepository(
            checks: FakeRecordRepository.todaysChecks, homework: FakeRecordRepository.todaysHomework
        )
        let ai = FakeAIRepository()
        let store = await store(
            classID: FakeClassesRepository.maths.id, ai: ai, attendance: attendance, record: record,
            textbooks: .seeded(), now: Self.at(7, 18, 40)
        )
        #expect(store.phase == .closed(at: FakeAttendanceRepository.closedAt))
        #expect(store.students.first { $0.name == "Hemanth Reddy" }?.present == false)
        let tapped = store.students.compactMap { student -> [Bool?]? in
            if case let .rows(rows) = student.checks {
                rows.map(\.tap)
            } else {
                nil
            }
        }
        #expect(tapped.flatMap(\.self).count { $0 == true } == 8 && ai.checkCalls.isEmpty)
        #expect(!store.students.contains { $0.present && !$0.homeworkGiven })
    }

    @Test func theCatchUpLineNamesTheMissedDays() async {
        let store = await store(
            attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithNikhilAbsentTwice)
        )
        #expect(store.students[index(store, "Nikhil Das")].catchUp == "Catch up · missed Mon and Fri")
        #expect(store.students[index(store, "Dev Kumar")].catchUp == nil)
    }
}
