import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import AppShell

@MainActor struct StatusLineTests {
    let calendar = DayHeading.india
    var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 35)) ?? Date()
    }

    var saved: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 14, minute: 10)) ?? Date()
    }

    @Test func offlineWordsNameTheCacheOrItsAbsence() {
        #expect(StatusLineModel.offline(savedAt: saved, now: now, calendar: calendar).text
            == "Offline. Showing what was saved at 14:10.")
        #expect(StatusLineModel.offline(savedAt: nil, now: now, calendar: calendar).text
            == "Offline. Nothing saved on this iPhone yet.")
        #expect(StatusLineModel.sending(3).text == "Back online. Sending 3 saved changes…" && StatusLineModel.sending(3)
            .spinner)
        #expect(StatusLineModel.sending(1).text == "Back online. Sending 1 saved change…")
        #expect(StatusLineModel.failed(1) {}.text == "1 saved change couldn't be sent.")
        #expect(StatusLineModel.failed(2) {}.text == "2 saved changes couldn't be sent.")
        #expect(StatusLineModel.signInAgain.text == "Sign in again to send your saved changes.")
    }

    @Test func theRunWinsOverTheOfflineLine() {
        let offline = RootView.statusLine(
            LineInputs(run: .idle, online: false, offlineRead: false, savedAt: saved),
            now: now, calendar: calendar
        ) {}
        #expect(offline?.text == "Offline. Showing what was saved at 14:10.")
        let sending = RootView.statusLine(
            LineInputs(run: .sending(3), online: true, offlineRead: false, savedAt: nil),
            now: now, calendar: calendar
        ) {}
        #expect(sending?.spinner == true)
        let failed = RootView.statusLine(
            LineInputs(run: .failed(1), online: false, offlineRead: false, savedAt: saved),
            now: now, calendar: calendar
        ) {}
        #expect(failed?.text == "1 saved change couldn't be sent." && failed?.action != nil)
        // A captive network: the monitor says online, the root's read failed for the network.
        let captive = RootView.statusLine(
            LineInputs(run: .idle, online: true, offlineRead: true, savedAt: saved),
            now: now, calendar: calendar
        ) {}
        #expect(captive?.text == "Offline. Showing what was saved at 14:10.")
        #expect(RootView.statusLine(
            LineInputs(run: .idle, online: true, offlineRead: false, savedAt: saved),
            now: now, calendar: calendar
        ) {} == nil)
    }
}

struct RunStateTests {
    @Test func theOutcomeBecomesTheStateAndTheToast() {
        #expect(RunState.after(.done(sent: 3, failed: 0)) == .idle)
        #expect(RunState.after(.done(sent: 1, failed: 2)) == .failed(2))
        #expect(RunState.after(.offline(sent: 1)) == .idle)
        #expect(RunState.after(.signedOut(sent: 0)) == .signedOut)
        #expect(RunState.toast(for: .done(sent: 3, failed: 0)) == "3 saved changes sent.")
        #expect(RunState.toast(for: .done(sent: 1, failed: 1)) == "1 saved change sent.")
        #expect(RunState.toast(for: .done(sent: 0, failed: 1)) == nil)
        #expect(RunState.toast(for: .offline(sent: 2)) == "2 saved changes sent.")
    }
}
