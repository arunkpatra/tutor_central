import Data
import Domain
import Foundation
import Testing
@testable import Students

/// The parent withdrew (P18-Consent-Change, -Withdraw, P18-Student-Withdrawn; plan/phase-18-plan.md decisions 15, 16):
/// Hemanth's parent agreed in person on Thursday 1 October; it is Monday 12 October.
@MainActor struct ConsentWithdrawTests {
    nonisolated static let monday = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 12,
        hour: 10
    )) ?? Date()
    nonisolated static let agreedAt = DayHeading.india.date(from: DateComponents(
        year: 2026,
        month: 10,
        day: 1,
        hour: 18
    )) ?? Date()
    let hemanth = FakeStudentsRepository.hemanth

    struct World {
        let store: ConsentStore
        let register: RegisterStore
        let students: FakeStudentsRepository
    }

    func world(agreed: Bool = true, events: [ConsentEvent]? = nil, online: Bool = true) async -> World {
        let seed = FakeStudentsRepository.seed.map { student in
            var changed = student
            if student.id == hemanth, agreed, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: Self.agreedAt, phone: phone, how: .inPerson)
            }
            return changed
        }
        let phone = seed.first { $0.id == hemanth }?.parentPhone
        let students = FakeStudentsRepository(students: seed)
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: students,
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil, now: { Self.monday }
        )
        await register.load()
        let history = FakeConsentHistoryRepository(events: [
            hemanth: events ?? [ConsentEvent(kind: .given, how: .inPerson, at: Self.agreedAt, phone: phone)],
        ])
        let store = ConsentStore(
            studentID: hemanth, register: register, messages: FakeMessageLogRepository(now: { Self.monday }),
            history: history, tutorName: "Meera Nair", centreName: "Bright Minds Tuition", now: { Self.monday },
            online: { online }
        )
        await store.load()
        return World(store: store, register: register, students: students)
    }

    @Test func withdrawingCallsTheServerWithHowAndTheDayAndShowsWithdrawn() async throws {
        let world = await world()
        let store = world.store
        #expect(store.historyLines.isEmpty)
        store.withdrawSheet.how = .call
        #expect(store.withdrewOnText == "Today, 12 Oct")
        #expect(await store.withdraw())
        let call = try #require(world.students.withdrawals.first)
        #expect(call.student == hemanth && call.how == .call && call.day == Day(year: 2026, month: 10, day: 12))
        guard case .withdrawn = store.state else { Issue.record("not withdrawn: \(store.state)")
            return
        }
        #expect(store.title == "Lakshmi Reddy withdrew" && store.line == "Mon 12 Oct · on a call")
        #expect(store.historyLines.map(\.what) == ["Withdrew · on a call", "Agreed · in person · +91 93802 60871"])
        #expect(store.historyLines.map(\.day) == ["Mon 12 Oct", "Thu 1 Oct"])
        #expect(store.footnote == "Nothing about Hemanth goes to the AI service now. His notes, marking and messages "
            + "wait until his parent agrees again; sheets and sets for his group go on.")
    }

    @Test func theDayCannotBeBeforeTheAgreementOrAfterToday() async {
        let store = await world().store
        #expect(store.withdrawDays == Day(year: 2026, month: 10, day: 1)! ... Day(year: 2026, month: 10, day: 12)!)
    }

    @Test func theHistoryShowsNewestFirstOnlyBeyondTheFirstAgreement() async {
        let only = await world().store
        #expect(only.historyLines.isEmpty)
        let again = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 9)) ?? Date()
        let withdrew = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12)) ?? Date()
        let store = await world(events: [
            ConsentEvent(kind: .given, how: .inPerson, at: Self.agreedAt, phone: nil),
            ConsentEvent(kind: .given, how: .whatsapp, at: again, phone: nil),
            ConsentEvent(kind: .withdrawn, how: .call, at: withdrew, phone: nil),
        ]).store
        #expect(store.historyLines.map(\.day) == ["Sun 11 Oct", "Mon 5 Oct", "Thu 1 Oct"])
        #expect(store.historyLines.first?.what == "Agreed · on WhatsApp")
    }

    @Test func withdrawnIsTheStateWhenNothingIsRecordedAndTheLastEventWithdrew() async {
        let store = await world(agreed: false, events: [
            ConsentEvent(kind: .withdrawn, how: .call, at: Self.monday, phone: nil),
            ConsentEvent(kind: .given, how: .inPerson, at: Self.agreedAt, phone: nil),
        ]).store
        guard case .withdrawn = store.state else { Issue.record("not withdrawn: \(store.state)")
            return
        }
    }

    @Test func offlineTheWithdrawalIsRefusedWithTheConsentWordsAndTheSheetStays() async {
        let world = await world(online: false)
        #expect(await !world.store.withdraw())
        #expect(world.store.failure == OfflineRefusal.words(for: .consent))
        #expect(world.students.withdrawals.isEmpty && world.register.student(hemanth)?.consent != nil)
    }

    @Test func parentAgreedAfterAWithdrawalRecordsAGivenAgain() async {
        let world = await world()
        let store = world.store
        _ = await store.withdraw()
        store.sheet.how = .whatsapp
        #expect(await store.record())
        guard case .agreed = store.state else { Issue.record("not agreed: \(store.state)")
            return
        }
        #expect(store.history.map(\.kind) == [.given, .withdrawn, .given])
        #expect(store.historyLines.count == 3)
    }

    @Test func theRecordSheetStartsFromTheAgreementAndSaysWithdrawalKeepsTheHistory() async {
        let store = await world().store
        #expect(store.sheet.agreedOn == Day(year: 2026, month: 10, day: 1) && store.sheet.how == .inPerson)
        #expect(store.agreedOnText == "Thu 1 Oct")
        #expect(store.sheetFootnote == "Kept with Hemanth's record: the day, the number and how. If his parent changes "
            + "their mind, record it with Parent withdrew; the agreement stays in his history.")
        #expect(
            store.withdrawFootnote == "Kept in Hemanth's history: the day and how. What was made before stays in his "
                + "record until you delete him. You can record a new agreement any time."
        )
    }
}
