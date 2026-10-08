import AITools
import DesignSystem
import Domain
import Foundation
import Students
import SwiftUI

/// The AI tools' wiring: one store per centre (a call outlives its screen), the routes on the tab that asked, the
/// consent merged into the session's workspace, and the store's words as toasts.
extension RootView {
    func aiStore(for workspace: Workspace) -> AIStore {
        if let ai = shell.ai {
            return ai
        }
        let made = AIStore(
            workspace: workspace, register: register(for: workspace), ai: deps.ai, history: deps.aiHistory,
            centres: deps.centres, messages: deps.messages, attendance: deps.attendance, now: deps.now
        )
        made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
        if let launch, Self.aiStates.contains(launch) {
            made.forms = Fixtures.aiForms(for: launch)
        }
        made.onResult = { [shell] generation in
            let top = shell.tabs.paths[shell.tabs.selected]?.last
            let replaced = made.lastReplaced.map(Route.aiResult)
            if top == .aiForm(generation.kind) || (replaced != nil && top == replaced) {
                shell.tabs.push(.aiResult(generation.id))
            }
        }
        shell.ai = made
        return made
    }

    /// Scan register with its own store for this visit (the list lives only until Add or Back); Add pops to the
    /// Students list and offers Undo there (P6-Scan-Saved).
    func scanView(in workspace: Workspace) -> some View {
        let store = ScanStore(
            workspace: workspace, register: register(for: workspace), ai: deps.ai, students: deps.students,
            centres: deps.centres, now: deps.now
        )
        store.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
        store.onAdded = { [shell, toasts] count in
            shell.tabs.remove(.scanRegister)
            shell.tabs.paths[.students] = []
            shell.tabs.selected = .students
            let ids = store.lastAdded
            toasts.show(ScanReview.addedToast(count: count), action: ("Undo", {
                Task {
                    if let failure = await store.undoAdd(ids: ids) {
                        toasts.show(failure)
                    }
                }
            }))
        }
        return ScanRegisterView(
            store: store, boardState: launch.flatMap(Self.scanBoardState), sample: launch.map(Fixtures.scanSample)
        )
    }

    /// One store per visit of Check a paper: its steps are pushed routes carrying the visit's id.
    func checkStore(_ id: UUID, in workspace: Workspace) -> CheckStore {
        if let visit = shell.check, visit.id == id {
            return visit.store
        }
        let made = CheckStore(
            workspace: workspace, register: register(for: workspace), ai: deps.ai, history: deps.aiHistory,
            students: deps.students, centres: deps.centres, now: deps.now
        )
        made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
        made.onStudentChanged = { [shell] in
            Task { await shell.register?.refresh() }
        }
        if let launch {
            Fixtures.prepareCheck(made, for: launch)
        }
        shell.check = CheckVisit(id: id, store: made)
        return made
    }

    @ViewBuilder
    func checkView(_ route: Route, in workspace: Workspace) -> some View {
        switch route {
        case let .checkPages(id):
            CheckPagesView(store: checkStore(id, in: workspace)) { shell.tabs.push(.checkScheme(id)) }
        case let .checkScheme(id):
            CheckSchemeView(
                store: checkStore(id, in: workspace), typed: launch == .checkSchemeTyped,
                showsFocus: launch == .checkSchemeTyped
            ) { shell.tabs.push(.checkResult(id)) }
        case let .checkResult(id):
            CheckResultView(store: checkStore(id, in: workspace), boardState: launch.flatMap(Self.checkBoardState)) {
                shell.tabs.remove(.checkResult(id))
                shell.tabs.remove(.checkScheme(id))
            }
        case let .checkPaper(id):
            CheckIntroView(store: checkStore(id, in: workspace)) { shell.tabs.push(.checkPages(id)) }
        default:
            EmptyView()
        }
    }

    var aiToolsActions: AIToolsActions {
        AIToolsActions(
            openStudent: { id in
                shell.tabs.select(.students)
                shell.tabs.paths[.students] = [.student(id)]
            },
            openResult: { shell.tabs.push(.aiResult($0)) },
            openForm: { shell.tabs.push(.aiForm($0)) },
            openHistory: { shell.tabs.push(.aiHistory) }
        )
    }

    /// The AI tools' screens, built with the centre's store and the launch's board state.
    @ViewBuilder func toolsView(_ route: Route) -> some View {
        if case let .ready(workspace) = session.state {
            let store = aiStore(for: workspace)
            let board = launch.flatMap(Self.aiBoardState)
            Group {
                switch route {
                case let .aiForm(kind):
                    GenerateFormView(
                        store: store, kind: kind, boardState: board, showsFocus: launch.map(Self.showsFocus) ?? false
                    )
                case let .aiResult(id):
                    ResultView(
                        store: store, generationID: id, boardState: board, onMessage: { toasts.show($0) },
                        onMissing: { shell.tabs.remove(.aiResult(id)) }
                    )
                case .aiHistory:
                    HistoryView(store: store, actions: aiToolsActions)
                case .scanRegister:
                    scanView(in: workspace)
                case .checkPaper, .checkPages, .checkScheme, .checkResult:
                    checkView(route, in: workspace)
                default:
                    AssistantView(store: store, actions: aiToolsActions)
                }
            }
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                toasts.show(message)
                store.message = nil
            }
        }
    }
}
