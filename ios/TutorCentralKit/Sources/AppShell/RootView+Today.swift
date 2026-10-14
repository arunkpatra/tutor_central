import Data
import DesignSystem
import Domain
import SwiftUI
import Today
import UIKit

/// Today's wiring: its one store and its actions.
extension RootView {
    /// One Today store for the life of the workspace, so its counts survive a tab switch; it reads the shared register
    /// and tasks.
    @ViewBuilder var todayView: some View {
        if case let .ready(workspace) = session.state {
            let store = shell.today ?? TodayStore(
                workspace: workspace, counts: deps.counts, register: register(for: workspace),
                attendance: deps.attendance, events: deps.events, tasks: tasksStore(for: workspace), now: deps.now,
                cache: cachedRead(workspace, "today"), record: deps.record
            )
            TodayView(
                store: store,
                actions: TodayActions(
                    openSettings: { shell.tabs.push(.settings) },
                    openTab: { shell.tabs.select($0) },
                    openSchedule: { shell.tabs.push(.schedule) },
                    openClose: { shell.tabs.push(.close($0)) },
                    openClass: { shell.tabs.push(.classroom($0)) },
                    openEvent: { shell.tabs.push(.event($0)) },
                    openFeesDue: { openFeesDue(in: workspace) },
                    openAI: { shell.tabs.push(.make) },
                    openScanRegister: { shell.tabs.push(.scanRegister) },
                    openArtefact: { shell.tabs.push(.artefact($0)) },
                    sendToParent: { row in sendToParent(row, workspace: workspace) },
                    openStudent: { shell.tabs.push(.student($0)) }
                ),
                ticks: !deps.fixedClock,
                boardState: launch.flatMap(Self.todayBoardState),
                status: rootStatus(savedAt: store.savedAt, offlineRead: store.offlineRead)
            )
            .onAppear {
                if shell.today == nil {
                    shell.today = store
                    shell.schoolItemsChanged = { [weak store] students in
                        Task { await store?.remakePlans(for: students) }
                    }
                }
                store.schoolItems = deps.schoolItems
                store.messages = deps.messages
                if store.makePlanStore == nil {
                    store.makePlanStore = planStoreMaker(workspace, register: register(for: workspace))
                }
                if store.noteDay == nil {
                    store.noteDay = noteDayStore(workspace)
                }
                // A close kept on this iPhone reads closed on the hero before it is sent (D39).
                store.queue = centreQueue()
            }
            .onChange(of: store.tasks.message) { _, message in
                guard let message else { return }
                Haptic.play(.error)
                notices.show(message, retry: store.tasks.canRetry ? Self.retry(store.tasks) : nil)
                store.tasks.message = nil
            }
        }
    }

    /// A batch's plan store: the plan and its job read as the user (D60), the preview's reads, the plan's copy on this
    /// iPhone, the network's state, whether the app is in front.
    func planStoreMaker(_ workspace: Workspace, register: any Register) -> (UUID) -> PlanStore {
        let cache = deps.cachesLists ? PlanCache(centre: workspace.centre.id, directory: deps.filesDirectory) : nil
        let preview = PlanPreview(
            plans: deps.plans, textbooks: deps.textbooks, attendance: deps.attendance, schoolItems: deps.schoolItems,
            cache: cache, now: deps.now, calendar: DayHeading.india
        )
        return { [deps] classID in
            let store = PlanStore(
                classID: classID, workspace: workspace, register: register, plans: deps.plans, classes: deps.classes,
                jobs: deps.jobs, preview: preview, cache: cache, now: deps.now, calendar: DayHeading.india
            )
            store.online = { [connectivity = deps.connectivity] in await connectivity.isOnline }
            store.inFront = { UIApplication.shared.applicationState == .active }
            store.messages = deps.messages
            return store
        }
    }

    /// The note day (Phase 14): the register, the record and the log as the user; Read opens the note (Artefacts).
    func noteDayStore(_ workspace: Workspace) -> NoteDayStore {
        let store = NoteDayStore(
            workspace: workspace, register: register(for: workspace), textbooks: deps.textbooks, record: deps.record,
            attendance: deps.attendance, messages: deps.messages, schoolItems: deps.schoolItems, classes: deps.classes,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }, now: deps.now,
            calendar: DayHeading.india
        )
        store.onOpenNote = { student, noteDay in shell.tabs.push(.note(student, noteDay)) }
        store.onOpenStudent = { shell.tabs.push(.student($0)) }
        store.plans = deps.plans
        return store
    }
}
