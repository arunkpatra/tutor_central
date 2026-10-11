import Data
import Domain
import Foundation
import Testing
@testable import Students

/// The sent log (P10-Student-Messages; plan/phase-14-plan.md decisions 6 and 7): by month, newest first, the kind, the
/// day, the language and opened, copied or not opened yet; a Held section with Send now.
@MainActor struct MessagesStoreTests {
    static let calendar = DayHeading.india
    static let dev = FakeStudentsRepository.dev
    static let riya = FakeStudentsRepository.riya

    static func at(_ month: Int, _ day: Int, _ hour: Int = 18) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: 0))!
    }

    static func entry(
        _ kind: MessageKind, _ month: Int, _ day: Int, language: MessageLanguage? = .hindi,
        channel: MessageChannel = .whatsAppLink, hour: Int = 18
    ) -> MessageEntry {
        MessageEntry(id: UUID(), kind: kind, openedAt: at(month, day, hour), language: language, channel: channel)
    }

    static func note(week monday: Day, madeAt: Date) -> Artefact {
        let content = NoteContent(
            message: "नमस्ते", english: "Hello", language: .hindi, weekMonday: monday, facts: [], generationID: nil
        )
        return Artefact(
            id: UUID(), kind: .note, source: .made, title: "Dev's week", content: .note(content), photoPath: nil,
            studentID: dev, planID: nil, regeneratedFrom: nil, madeAt: madeAt
        )
    }

    static var thisWeeksNote: Artefact {
        note(week: Day(year: 2026, month: 10, day: 5)!, madeAt: at(10, 11, 18))
    }

    static func students() -> [Student] {
        FakeStudentsRepository.eveningSeed.map { student in
            var changed = student
            changed.messageLanguage = [dev, riya].contains(student.id) ? .hindi : .english
            if student.id != riya, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: at(9, 1), phone: phone, how: .inPerson)
            }
            return changed
        }
    }

    static func make(
        _ student: UUID, entries: [MessageEntry] = [], notes: [Artefact] = [], now: Date = at(10, 11, 19),
        fails: Bool = false
    ) async -> MessagesStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students()),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.loadIfNeeded()
        let log = FakeMessageLogRepository(entries: [student: entries], now: { now })
        if fails {
            log.messagesFailure = URLError(.notConnectedToInternet)
        }
        return MessagesStore(
            student: student, centre: FakeCentreRepository.meeraWorkspace.centre.id, register: register, messages: log,
            plans: FakePlansRepository(artefacts: notes),
            now: { now }, calendar: calendar
        )
    }

    @Test func theLogListsByMonthNewestFirstWithKindDayLanguageAndOpened() async {
        let entries = [
            Self.entry(.note, 10, 5, hour: 9), Self.entry(.reminder, 10, 6, language: nil),
            Self.entry(.testTomorrow, 10, 7), Self.entry(.notOnTrack, 10, 9), Self.entry(.note, 9, 28),
            Self.entry(.receipt, 9, 24, language: nil),
        ]
        let store = await Self.make(Self.dev, entries: entries)
        await store.load()
        #expect(store.title == "Messages · Dev" && store.months.map(\.title) == ["October", "September"])
        #expect(store.months[0].rows.map(\.title) == ["Not on track", "Test tomorrow", "Fee reminder", "Weekly note"])
        #expect(store.months[0].rows[0].line == "Fri 9 Oct · Hindi · opened Fri")
        #expect(store.months[0].rows[2].line == "Tue 6 Oct · English")
        #expect(store.months[0].rows[0].symbol == "exclamationmark.circle" && store.months[0].rows[3]
            .symbol == "text.bubble")
        #expect(store.line.hasPrefix("What went to Ramesh Kumar from here, newest first."))
    }

    @Test func aNoteKeptWithNoRowReadsNotOpenedYetAndACopiedOneCopied() async {
        let store = await Self.make(Self.dev, notes: [Self.thisWeeksNote], now: Self.at(10, 14))
        await store.load()
        #expect(store.months[0].rows[0].line == "Sun 11 Oct · Hindi · not opened yet")
        #expect(store.months[0].rows[0].opens == Day(year: 2026, month: 10, day: 11))
        let copied = await Self.make(
            Self.dev, entries: [Self.entry(.note, 10, 11, channel: .copied, hour: 19)], notes: [Self.thisWeeksNote],
            now: Self.at(10, 14)
        )
        await copied.load()
        #expect(copied.months[0].rows[0].line == "Sun 11 Oct · Hindi · copied Sun")
        let late = await Self.make(
            Self.dev, entries: [Self.entry(.note, 10, 12, hour: 9)], notes: [Self.thisWeeksNote], now: Self.at(10, 14)
        )
        await late.load()
        #expect(late.months[0].rows[0].line == "Sun 11 Oct · Hindi · opened Mon" && late.months[0].rows.count == 1)
    }

    @Test func aHeldNoteSitsAfterThisMonthWithSendNow() async {
        let three = [Self.entry(.testTomorrow, 10, 6), Self.entry(.testTomorrow, 10, 7), Self.entry(.notOnTrack, 10, 9)]
        let store = await Self.make(Self.dev, entries: three, notes: [Self.thisWeeksNote])
        await store.load()
        #expect(store.held?.title == "Weekly note")
        #expect(store.held?.line == "Held since Sun 11 Oct · Ramesh had three messages that week")
        #expect(store.sendNow()?.0 == Self.dev && store.sendNow()?.1 == Day(year: 2026, month: 10, day: 11))
        #expect(!store.months[0].rows.contains { $0.line.hasPrefix("Sun 11 Oct") })
    }

    @Test func aHeldNoteOffersSendNowOnceTheWeekRolls() async {
        let three = [Self.entry(.testTomorrow, 10, 6), Self.entry(.testTomorrow, 10, 7), Self.entry(.notOnTrack, 10, 9)]
        let store = await Self.make(Self.dev, entries: three, notes: [Self.thisWeeksNote], now: Self.at(10, 13, 9))
        await store.load()
        #expect(store.held != nil && store.sendNow() != nil)
    }

    @Test func theNextNoteDaysNoteReplacesAHeldOne() async throws {
        let three = [Self.entry(.testTomorrow, 10, 6), Self.entry(.testTomorrow, 10, 7), Self.entry(.notOnTrack, 10, 9)]
        let next = try Self.note(week: #require(Day(year: 2026, month: 10, day: 12)), madeAt: Self.at(10, 18, 18))
        let store = await Self.make(
            Self.dev, entries: three, notes: [Self.thisWeeksNote, next], now: Self.at(10, 18, 19)
        )
        await store.load()
        #expect(store.held == nil)
        #expect(store.months[0].rows.filter { $0.title == "Weekly note" }.count == 2)
    }

    @Test func aHeldForConsentNoteNamesTheReason() async {
        let store = await Self.make(Self.riya)
        await store.load()
        #expect(store.held?.line == "Held since Sun 11 Oct · waits for Neha's consent")
        // No note is made without consent: Send now goes back to the page, where it is recorded.
        #expect(store.sendNow() == nil && store.held?.waitsForConsent == true)
    }

    @Test func aFailedReadSaysSoInPlace() async {
        let store = await Self.make(Self.dev, fails: true)
        await store.load()
        #expect(store.loadFailed && store.months.isEmpty)
    }
}

extension MessagesStoreTests {
    @Test func aHeldNoteSentLaterInTheWeekIsOneRowReadingItsSend() async {
        // Made Sunday the 11th, held, sent from Send now on Wednesday the 14th.
        let store = await Self.make(
            Self.dev, entries: [Self.entry(.note, 10, 14)], notes: [Self.thisWeeksNote], now: Self.at(10, 14, 19)
        )
        await store.load()
        let notes = store.months.flatMap(\.rows).filter { $0.title == "Weekly note" }
        #expect(notes.map(\.line) == ["Sun 11 Oct · Hindi · opened Wed"])
    }
}
