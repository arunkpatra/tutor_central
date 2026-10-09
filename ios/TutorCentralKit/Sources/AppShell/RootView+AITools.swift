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
        made.historyCache = cachedRead(workspace, "ai-history")
        if let launch, Self.aiStates.contains(launch) {
            made.forms = Fixtures.aiForms(for: launch)
        }
        made.onResult = Self.resultHandler(for: made, shell: shell)
        shell.ai = made
        return made
    }

    /// The result handler, holding its store weakly: the store owns the closure (Phase 6's minor 1).
    static func resultHandler(for store: AIStore, shell: ShellState) -> (Generation) -> Void {
        { [weak store, shell] generation in
            guard let store else { return }
            let top = shell.tabs.paths[shell.tabs.selected]?.last
            let replaced = store.lastReplaced.map(Route.aiResult)
            if top == .aiForm(generation.kind) || (replaced != nil && top == replaced) {
                shell.tabs.push(.aiResult(generation.id))
            }
        }
    }

    /// After Add: the scan's screen leaves, Students shows the added count with Undo (P6-Scan-Saved), and the visit's
    /// store is let go. The handler holds its store weakly; the Undo holds it on purpose, so the toast can undo after
    /// the screen has gone (the toast's life bounds it).
    static func addedHandler(for store: ScanStore, shell: ShellState, toasts: ToastCenter) -> (Int) -> Void {
        { [weak store, shell, toasts] count in
            guard let store else { return }
            shell.tabs.remove(.scanRegister)
            shell.tabs.paths[.students] = []
            shell.tabs.selected = .students
            let ids = store.lastAdded
            shell.endScan()
            toasts.show(ScanReview.addedToast(count: count), action: ("Undo", {
                Task {
                    if let failure = await store.undoAdd(ids: ids) {
                        toasts.show(failure)
                    }
                }
            }))
        }
    }

    /// Scan register with one store for the visit (the list lives only until Add or Back), kept on the shell so a
    /// redraw never makes another.
    func scanView(in workspace: Workspace) -> some View {
        let store = if let visit = shell.scan, visit.number == shell.tabs.scanVisits {
            visit.store
        } else {
            makeScanStore(in: workspace)
        }
        return ScanRegisterView(
            store: store, boardState: launch.flatMap(Self.scanBoardState), sample: launch.map(Fixtures.scanSample),
            onLeave: { shell.endScan() }
        )
    }

    private func makeScanStore(in workspace: Workspace) -> ScanStore {
        let made = ScanStore(
            workspace: workspace, register: register(for: workspace), ai: deps.ai, students: deps.students,
            centres: deps.centres, now: deps.now
        )
        made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
        made.onAdded = Self.addedHandler(for: made, shell: shell, toasts: toasts)
        // A rebuild while the route leaves (its pop) must not leave a spare store on the shell.
        if shell.tabs.scanOnStack {
            shell.scan = ScanVisit(number: shell.tabs.scanVisits, store: made)
        }
        return made
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
                    HistoryView(
                        store: store, actions: aiToolsActions,
                        status: rootStatus(savedAt: store.historySavedAt, offlineRead: store.historyOfflineRead)
                    )
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

/// A scan visit ends when its route leaves the stack, however it left: Back, Add, or a tab popped to its root.
struct EndsScanVisits: ViewModifier {
    let shell: ShellState

    func body(content: Content) -> some View {
        content.onChange(of: shell.tabs.scanOnStack) { _, onStack in
            if !onStack {
                shell.endScan()
            }
        }
    }
}
