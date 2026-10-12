import Data
import Domain
import Foundation
import Students
import Testing
@testable import Today

/// The note day on Today (P10-Today-NoteDay, P10-Held; plan/phase-14-plan.md decisions 4 to 6). The fixtures' Evening
/// batch (Dev in Hindi and Nikhil in Kannada agreed, Meher in English agreed, Riya in Hindi not agreed, Sahil in
/// Kannada
/// agreed on the ladder) and Class 10 Maths (Hemanth in Hindi and Akshita in English agreed; the others with no
/// number).
@MainActor struct NoteDayStoreTests {
    static let calendar = DayHeading.india
    static let sunday1830 = PlanTest.at(11, 18, 30)
    static let dev = FakeStudentsRepository.dev
    static let meher = FakeStudentsRepository.meher
    static let nikhil = FakeStudentsRepository.nikhil
    static let riya = FakeStudentsRepository.riya
    static let sahil = FakeStudentsRepository.sahil
    static let hemanth = FakeStudentsRepository.hemanth
    static let akshita = FakeStudentsRepository.id(1)

    struct World {
        var now = PlanTest.at(11, 18, 30)
        var sent: Set<UUID> = []
        var sentAt = PlanTest.at(11, 18, 20)
        var thisWeek: [UUID: [MessageKind]] = [:]
        var noNumber: Set<UUID> = []
        var sameParent: Set<UUID> = []
        var riyaAgreed = false
        var eveningNoteDay: NoteDay?
        var recordFails = false
        var online = true
        var classes: FakeClassesRepository?
        var messages: FakeMessageLogRepository?
        var items: FakeSchoolItemsRepository?
    }

    static func students(_ world: World) -> [Student] {
        let agreed = [dev, meher, nikhil, sahil, hemanth, akshita] + (world.riyaAgreed ? [riya] : [])
        let languages: [UUID: MessageLanguage] = [
            dev: .hindi,
            nikhil: .kannada,
            riya: .hindi,
            sahil: .kannada,
            hemanth: .hindi,
        ]
        return FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            changed.messageLanguage = languages[student.id] ?? .english
            if agreed.contains(student.id), let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: PlanTest.at(1, 10, 0), phone: phone, how: .whatsapp)
            }
            let listed = [dev, meher, nikhil, riya, sahil, hemanth, akshita]
            if !listed.contains(student.id) || world.noNumber.contains(student.id) {
                changed.parentPhone = nil
            }
            if world.sameParent.contains(student.id) {
                changed.parentPhone = PhoneNumber(e164: "+919830012345")
            }
            return changed
        }
    }

    static func make(_ world: World) async -> NoteDayStore {
        let now = world.now
        var classes = FakeClassesRepository.withEvening
        if let day = world.eveningNoteDay, let index = classes.firstIndex(where: { $0.id == PlanTest.evening.id }) {
            classes[index].noteDay = day
        }
        let students = students(world)
        let classesRepository = world.classes ?? FakeClassesRepository(classes: classes)
        classesRepository.classes = classes
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: classesRepository, cache: nil, now: { now }
        )
        await register.loadIfNeeded()
        let messages = world.messages ?? FakeMessageLogRepository(now: { now })
        var entries: [UUID: [MessageEntry]] = [:]
        for id in world.sent {
            entries[id, default: []].append(MessageEntry(
                id: UUID(), kind: id == sahil ? .canDo : .note, openedAt: world.sentAt, language: .hindi
            ))
        }
        for (id, kinds) in world.thisWeek {
            for (index, kind) in kinds.enumerated() {
                entries[id, default: []].append(MessageEntry(
                    id: UUID(), kind: kind, openedAt: PlanTest.at(6 + index, 18, 0), language: .hindi
                ))
            }
        }
        messages.entries = entries
        let record = FakeRecordRepository(checks: weekChecks, homework: [], marks: [])
        let textbooks = FakeTextbooksRepository.evening()
        if world.recordFails {
            record.nextError = URLError(.badServerResponse)
        }
        return NoteDayStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register, textbooks: textbooks, record: record,
            attendance: FakeAttendanceRepository(sessions: weekSessions), messages: messages,
            schoolItems: world.items ?? FakeSchoolItemsRepository(items: []), classes: classesRepository,
            online: { [online = world.online] in online }, now: { now }, calendar: calendar
        )
    }

    /// The Evening batch on Monday, Wednesday and Friday: Dev absent Monday and Wednesday, Nikhil Wednesday.
    static var weekSessions: [AttendanceSession] {
        let members = FakeStudentsRepository.eveningSeed.filter { $0.classID == PlanTest.evening.id }
        return [5, 7, 9].map { day in
            var marks = Dictionary(uniqueKeysWithValues: members.map { ($0.id, AttendanceStatus.present) })
            if day != 9 {
                marks[dev] = .absent
            }
            if day == 7 {
                marks[nikhil] = .absent
            }
            return AttendanceSession(
                id: UUID(), classID: PlanTest.evening.id, date: Day(year: 2026, month: 10, day: day)!,
                savedAt: PlanTest.at(day, 18, 30), marks: marks, closedAt: PlanTest.at(day, 18, 30)
            )
        }
    }

    /// Meher's four checks this week, all right.
    static var weekChecks: [CheckRecord] {
        (0 ..< 4).map { index in
            CheckRecord(
                id: UUID(), studentID: meher, skillID: UUID(), sessionID: nil, question: "Q\(index)", correct: true,
                at: PlanTest.at(9, 18, 0), isPlacement: false
            )
        }
    }

    func row(_ store: NoteDayStore, _ id: UUID) -> NoteRowModel? {
        store.rows.first { $0.id == id }
    }

    @Test func onTheNoteDayTheHeroCountsTheNotesAndTheRowsReadTheWeek() async {
        let store = await Self.make(World(sent: [Self.dev, Self.meher]))
        await store.load()
        #expect(store.isOn && store.heroLine == "7 notes for parents")
        #expect(store.rows.map(\.name) == [
            "Dev Kumar", "Meher Shah", "Akshita Rao", "Hemanth Reddy", "Nikhil Das", "Sahil Verma", "Riya Sharma",
        ])
        #expect(row(store, Self.dev)?.state == .sent && row(store, Self.dev)?.line.hasSuffix("· 2 absences") == true)
        #expect(row(store, Self.dev)?.line.hasPrefix("Hindi · ") == true)
        #expect(row(store, Self.nikhil)?.line.hasSuffix("· absent Wed") == true)
        #expect(row(store, Self.sahil)?.line.hasPrefix("Kannada · Can now ") == true)
        #expect(row(store, Self.sahil)?.state == .read)
        #expect(row(store, Self.riya)?.line == "Hindi · waits for Neha's consent")
        #expect(row(store, Self.riya)?.state == .held(.consent(parentFirstName: "Neha")))
        #expect(store.countLine == "2 of 7 sent")
    }

    @Test func beforeTheNoteTimeAndAfterTheNextDayNothingShows() async {
        let before = await Self.make(World(now: PlanTest.at(11, 17, 0)))
        await before.load()
        #expect(!before.isOn && before.rows.isEmpty)
        let monday = await Self.make(World(now: PlanTest.at(12, 20, 0)))
        await monday.load()
        #expect(monday.isOn)
        let tuesday = await Self.make(World(now: PlanTest.at(13, 9, 0)))
        await tuesday.load()
        #expect(!tuesday.isOn)
    }

    @Test func aParentWithThreeThisWeekIsHeldAndTheSheetListsThem() async {
        let store = await Self.make(World(thisWeek: [Self.dev: [.testTomorrow, .testTomorrow, .notOnTrack]]))
        await store.load()
        #expect(row(store, Self.dev)?.state == .held(.threeThisWeek))
        #expect(row(store, Self.dev)?.line == "Hindi · held: three messages this week")
        let held = store.held(for: Self.dev)
        #expect(held?.parentLine == "Ramesh Kumar · Dev's parent")
        #expect(held?.thisWeek.map(\.kind) == ["Test tomorrow", "Test tomorrow", "Not on track"])
        #expect(held?.thisWeek.map(\.day) == ["Tue 6 Oct", "Wed 7 Oct", "Thu 8 Oct"])
        #expect(held?.footnote.contains("waits for Sunday the 18th") == true)
    }

    @Test func aHandSendNeverHolds() async {
        let store = await Self.make(World(thisWeek: [Self.dev: [.reminder, .absence, .receipt]]))
        await store.load()
        #expect(row(store, Self.dev)?.state == .read)
    }

    @Test func aParentOfTwoSeesBothNotesAndTheFourthHeld() async {
        let both = await Self.make(World(
            sent: [Self.nikhil, Self.riya], thisWeek: [Self.nikhil: [.testTomorrow]], sameParent: [
                Self.nikhil,
                Self.riya,
            ],
            riyaAgreed: true
        ))
        await both.load()
        #expect(row(both, Self.nikhil)?.state == .sent && row(both, Self.riya)?.state == .sent)
        let fourth = await Self.make(World(
            sent: [Self.nikhil], thisWeek: [Self.nikhil: [.testTomorrow, .testTomorrow]],
            sameParent: [Self.nikhil, Self.riya], riyaAgreed: true
        ))
        await fourth.load()
        #expect(row(fourth, Self.riya)?.state == .held(.threeThisWeek))
    }

    @Test func aStudentWithoutANumberIsNotListed() async {
        let store = await Self.make(World(noNumber: [Self.meher]))
        await store.load()
        #expect(row(store, Self.meher) == nil && store.heroLine == "6 notes for parents")
    }

    @Test func aBatchWithItsOwnNoteDayShowsOnThatDay() async throws {
        let saturday = try NoteDay(weekday: .saturday, time: #require(TimeOfDay(hour: 18, minute: 0)))
        let store = await Self.make(World(now: PlanTest.at(10, 18, 30), eveningNoteDay: saturday))
        await store.load()
        #expect(store.isOn && Set(store.rows.map(\.id)) == [Self.dev, Self.meher, Self.nikhil, Self.riya, Self.sahil])
        let sunday = await Self.make(World(eveningNoteDay: saturday))
        await sunday.load()
        // Saturday's notes still show on Sunday (to the end of the next day), with Sunday's for the default batches.
        #expect(sunday.rows.count == 7)
    }

    @Test func aWeekThatCannotBeReadListsTheRegistersRowsSoAKeptNoteStillOpens() async {
        let store = await Self.make(World(recordFails: true))
        await store.load()
        #expect(store.isOn && store.loadFailed && store.rows.count == 7)
        #expect(store.heroLine == "7 notes for parents" && store.countLine == "")
        #expect(row(store, Self.dev)?.line == "Hindi" && row(store, Self.dev)?.state == .read)
        #expect(row(store, Self.riya)?.line == "Hindi · waits for Neha's consent")
        #expect(row(store, Self.riya)?.state == .held(.consent(parentFirstName: "Neha")))
    }

    @Test func changeDayWritesTheBatchesWhoseNoteDayIsShownAndRefusesOffline() async {
        let classes = FakeClassesRepository()
        let store = await Self.make(World(classes: classes))
        await store.load()
        #expect(NoteDay.choices.contains(store.chosen) && store.chosen == .default)
        let saturday = NoteDay.choices[1]
        #expect(await store.changeDay(to: saturday))
        #expect(classes.noteDayCalls == [saturday, saturday])
        let shown = [PlanTest.evening.id, FakeClassesRepository.maths.id]
        #expect(classes.classes.filter { shown.contains($0.id) }.allSatisfy { $0.noteDay == saturday })
        let offline = await Self.make(World(online: false))
        await offline.load()
        #expect(await offline.changeDay(to: NoteDay.choices[0]) == false)
        #expect(offline.message == OfflineRefusal.words(for: .noteDay))
    }

    @Test func changingTheNoteDayKeepsThisWeeksSentRows() async {
        let store = await Self.make(World(sent: [Self.dev]))
        await store.load()
        #expect(await store.changeDay(to: NoteDay.choices[1]))
        #expect(row(store, Self.dev)?.state == .sent && store.isOn)
    }

    @Test func sendItNowOpensTheNoteAndKeepWritesNothing() async throws {
        let store = await Self.make(World(thisWeek: [Self.dev: [.testTomorrow, .testTomorrow, .notOnTrack]]))
        await store.load()
        var opened: (UUID, Day)?
        store.onOpenNote = { opened = ($0, $1) }
        let held = try? #require(store.held(for: Self.dev))
        try store.sendNow(#require(held))
        #expect(opened?.0 == Self.dev && opened?.1 == Day(year: 2026, month: 10, day: 11))
        #expect(row(store, Self.dev)?.state == .held(.threeThisWeek))
    }

    @Test func aNoteSentTheMorningAfterItsNoteDayStaysSent() async {
        var world = World(now: PlanTest.at(12, 9, 30), sent: [Self.dev])
        world.sentAt = PlanTest.at(12, 9, 0)
        let store = await Self.make(world)
        await store.load()
        #expect(row(store, Self.dev)?.state == .sent && row(store, Self.dev)?.noteDay == Day(
            year: 2026,
            month: 10,
            day: 11
        ))
    }

    @Test func lastWeeksNoteSentOnMondayMorningIsNotThisWeeks() async {
        var world = World(sent: [Self.dev])
        world.sentAt = PlanTest.at(5, 9, 0)
        let store = await Self.make(world)
        await store.load()
        #expect(row(store, Self.dev)?.state == .read)
    }
}

extension NoteDayStoreTests {
    @Test func aRowHeldForConsentOpensTheStudentNotTheCadenceSheet() async {
        let store = await Self.make(World())
        await store.load()
        var opened: [UUID] = []
        var notes: [UUID] = []
        store.onOpenStudent = { opened.append($0) }
        store.onOpenNote = { student, _ in notes.append(student) }
        #expect(store.held(for: Self.riya) == nil)
        let riya = try? #require(row(store, Self.riya))
        if let riya {
            store.open(riya)
        }
        #expect(opened == [Self.riya] && notes.isEmpty)
    }

    @Test func changeDayLeavesABatchWhoseNoteDayIsAnotherOne() async throws {
        // Sunday evening: the Evening batch's Saturday notes still show beside Class 10 Maths' Sunday ones.
        let saturday = try NoteDay(weekday: .saturday, time: #require(TimeOfDay(hour: 18, minute: 0)))
        let classes = FakeClassesRepository()
        let store = await Self.make(World(eveningNoteDay: saturday, classes: classes))
        await store.load()
        #expect(store.chosen == .default)
        let monday = NoteDay.choices[4]
        #expect(await store.changeDay(to: monday))
        #expect(classes.noteDayCalls == [monday])
        #expect(classes.classes.first { $0.id == PlanTest.evening.id }?.noteDay == saturday)
        #expect(classes.classes.first { $0.id == FakeClassesRepository.maths.id }?.noteDay == monday)
    }

    @Test func aSlowEarlierReadDoesNotLandOverANewerOne() async throws {
        let log = FakeMessageLogRepository(now: { PlanTest.at(11, 18, 30) })
        log.entriesDelay = .milliseconds(400)
        let store = await Self.make(World(messages: log))
        let slow = Task { await store.load() }
        try await Task.sleep(for: .milliseconds(100))
        log.entriesDelay = nil
        let sent = MessageEntry(id: UUID(), kind: .note, openedAt: PlanTest.at(11, 18, 20), language: .hindi)
        log.entries = [Self.dev: [sent]]
        await store.load()
        await slow.value
        #expect(row(store, Self.dev)?.state == .sent)
    }
}
