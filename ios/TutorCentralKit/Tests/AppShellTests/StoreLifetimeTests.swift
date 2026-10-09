import AITools
import Data
import DesignSystem
import Domain
import Foundation
import Students
import Testing
@testable import AppShell

/// Phase 6's minor 1: the AI and scan stores' handlers do not keep their own store alive, and Scan register keeps one
/// store per visit on the shell, let go on Add or Back.
@MainActor struct StoreLifetimeTests {
    static func register(_ deps: Dependencies) -> RegisterStore {
        RegisterStore(
            workspace: Fixtures.meeraWorkspace, students: deps.students, classes: deps.classes, cache: nil,
            now: { Fixtures.now }
        )
    }

    @Test func theAIStoreIsReleasedWithItsResultHandlerInstalled() {
        let deps = Fixtures.dependencies(for: .aiAssistant)
        let shell = ShellState()
        weak var weakStore: AIStore?
        do {
            let store = AIStore(
                workspace: Fixtures.meeraWorkspace, register: Self.register(deps), ai: deps.ai, history: deps.aiHistory,
                centres: deps.centres, messages: deps.messages, attendance: deps.attendance, now: { Fixtures.now }
            )
            store.onResult = RootView.resultHandler(for: store, shell: shell)
            weakStore = store
        }
        #expect(weakStore == nil, "the handler must not keep its own store alive")
    }

    @Test func theScanStoreIsReleasedWithItsAddedHandlerInstalledAndEndsWithItsVisit() {
        let deps = Fixtures.dependencies(for: .scanReview)
        let shell = ShellState()
        weak var weakStore: ScanStore?
        do {
            let store = ScanStore(
                workspace: Fixtures.meeraWorkspace, register: Self.register(deps), ai: deps.ai, students: deps.students,
                centres: deps.centres, now: { Fixtures.now }
            )
            store.onAdded = RootView.addedHandler(for: store, shell: shell, toasts: ToastCenter())
            shell.scan = ScanVisit(number: shell.tabs.scanVisits, store: store)
            weakStore = store
            shell.endScan()
            #expect(shell.scan == nil)
        }
        #expect(weakStore == nil)
    }

    @Test func eachPushOfScanRegisterIsANewVisit() {
        let tabs = TabsState(selected: .more)
        let first = tabs.scanVisits
        tabs.push(.schedule)
        #expect(tabs.scanVisits == first)
        tabs.push(.scanRegister)
        #expect(tabs.scanVisits == first + 1)
    }

    @Test func scanIsOnTheStackUntilItsRouteGoesFromAnyTab() {
        let tabs = TabsState(selected: .more)
        #expect(!tabs.scanOnStack)
        tabs.push(.scanRegister)
        #expect(tabs.scanOnStack)
        tabs.select(.more) // tapping the active tab pops it to its root
        #expect(!tabs.scanOnStack)
        tabs.push(.scanRegister)
        tabs.remove(.scanRegister)
        #expect(!tabs.scanOnStack)
    }
}
