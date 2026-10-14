import DesignSystem
import Domain
import Foundation
import Make
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
        // The last class and subject of each kind, kept on this iPhone (wiped at sign-out); the fixtures keep none.
        made.formDefaults = deps.cachesRegister ? .standard : nil
        if let launch, Self.aiStates.contains(launch) {
            made.forms = Fixtures.aiForms(for: launch)
        }
        made.onResult = Self.resultHandler(for: made, shell: shell)
        shell.ai = made
        return made
    }

    /// Make something's store: V1's results through the Assistant's store, Make's list with its copy on this iPhone.
    func makeStore(for workspace: Workspace) -> MakeStore {
        if let make = shell.make {
            return make
        }
        let made = MakeStore(
            workspace: workspace, register: register(for: workspace), plans: deps.plans, ai: aiStore(for: workspace),
            now: deps.now
        )
        made.madeCache = cachedRead(workspace, "make-made")
        shell.make = made
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
    static func addedHandler(
        for store: ScanStore, shell: ShellState, toasts: ToastCenter, notices: NoticeCenter
    ) -> (Int) -> Void {
        { [weak store, shell, toasts, notices] count in
            guard let store else { return }
            shell.tabs.remove(.scanRegister)
            shell.tabs.paths[.students] = []
            shell.tabs.selected = .students
            let ids = store.lastAdded
            shell.endScan()
            toasts.show(ScanReview.addedToast(count: count), action: ("Undo", {
                Task {
                    if let failure = await store.undoAdd(ids: ids) {
                        notices.show(failure)
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
        made.onAdded = Self.addedHandler(for: made, shell: shell, toasts: toasts, notices: notices)
        // A rebuild while the route leaves (its pop) must not leave a spare store on the shell.
        if shell.tabs.scanOnStack {
            shell.scan = ScanVisit(number: shell.tabs.scanVisits, store: made)
        }
        return made
    }

    /// What the result's Back takes off the stack: back at the scheme for a check begun here; a mock's (a preset) is
    /// left whole, back to where Mark from a photo started (hand run 9).
    static func leavingCheck(_ id: UUID, preset: Bool) -> [Route] {
        let routes: [Route] = [.checkResult(id), .checkScheme(id)]
        return preset ? routes + [.checkPages(id), .checkPaper(id)] : routes
    }

    /// One store per visit of Check a paper: its steps are pushed routes carrying the visit's id.
    func checkStore(_ id: UUID, in workspace: Workspace) -> CheckStore {
        if let visit = shell.check, visit.id == id {
            return visit.store
        }
        let made = CheckStore(
            workspace: workspace, register: register(for: workspace), ai: deps.ai, history: deps.aiHistory,
            students: deps.students, centres: deps.centres, now: deps.now, record: deps.record,
            preset: shell.checkPresets[id] ?? launch.flatMap(Fixtures.checkPreset), plans: deps.plans,
            schoolItems: deps.schoolItems
        )
        made.online = { [connectivity = deps.connectivity] in await connectivity.isOnline }
        made.jobs = deps.jobs
        made.onWorkspaceChanged = { changed in applyWorkspace { $0.takingAIConsent(from: changed) } }
        made.onStudentChanged = { [shell] in
            shell.recordChanged += 1
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
            let store = checkStore(id, in: workspace)
            CheckPagesView(store: store) {
                shell.tabs.push(store.skipsScheme ? .checkResult(id) : .checkScheme(id))
            }
        case let .checkScheme(id):
            CheckSchemeView(
                store: checkStore(id, in: workspace), typed: launch == .checkSchemeTyped,
                showsFocus: launch == .checkSchemeTyped
            ) { shell.tabs.push(.checkResult(id)) }
        case let .checkResult(id):
            CheckResultView(
                store: checkStore(id, in: workspace), boardState: launch.flatMap(Self.checkBoardState),
                backToPages: {
                    for route in Self.leavingCheck(id, preset: false) {
                        shell.tabs.remove(route)
                    }
                },
                leaveVisit: {
                    for route in Self.leavingCheck(id, preset: true) {
                        shell.tabs.remove(route)
                    }
                }
            )
        case let .checkPaper(id):
            CheckIntroView(
                store: checkStore(id, in: workspace), openPages: { shell.tabs.push(.checkPages(id)) },
                openSchemes: { shell.tabs.push(.checkSchemeChooser(id)) }
            )
        case let .checkSchemeChooser(id):
            CheckSchemeView(store: checkStore(id, in: workspace), chooser: true) {
                shell.tabs.remove(.checkSchemeChooser(id))
            }
        default:
            EmptyView()
        }
    }

    /// A Make kind's form with its own store (kept in the view's `@State`), the launch state's fields, and the outcome
    /// shown: the artefact's screen when the form or Make's home is on top, else it waits in Recent.
    func makeFormView(_ kind: MakeKind, in workspace: Workspace) -> some View {
        let make = makeStore(for: workspace)
        let context = MakeContext(
            workspace: workspace, register: register(for: workspace), plans: deps.plans, textbooks: deps.textbooks,
            schoolItems: deps.schoolItems, ai: deps.ai,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }, now: deps.now,
            calendar: DayHeading.india, defaults: deps.cachesRegister ? .standard : nil
        )
        return MakeFormView(
            store: MakeFormStore(kind: kind, context: context, make: make),
            boardState: launch.flatMap(Fixtures.makeBoardState),
            setUp: launch.map { state in { Fixtures.prepareMakeForm($0, for: state) } },
            onOutcome: { outcome, form in showMade(outcome, form: form, kind: kind) }
        )
    }

    private func showMade(_ outcome: MakeOutcome, form: MakeFormStore, kind: MakeKind) {
        let top = shell.tabs.paths[shell.tabs.selected]?.last
        let onTop = top == .makeForm(kind) || top == .make
        switch outcome {
        case let .made(artefact):
            if onTop {
                shell.tabs.push(.artefact(artefact.id))
            }
        case let .opensExisting(id):
            if onTop {
                shell.tabs.push(.artefact(id))
            }
        case let .opensNote(student, noteDay, words):
            shell.noteWords[student] = words
            shell.tabs.push(.note(student, noteDay))
        case .refused:
            if let alert = form.alert {
                notices.show(alert)
            }
        default:
            break
        }
    }

    /// A kind's form: V1's for the three V1 kinds (#122's forms, unchanged), Make's for the others.
    nonisolated static func formRoute(for kind: MakeKind) -> Route {
        kind.v1Kind.map(Route.aiForm) ?? .makeForm(kind)
    }

    var makeActions: MakeActions {
        MakeActions(
            openStudent: { id in
                shell.tabs.select(.students)
                shell.tabs.paths[.students] = [.student(id)]
            },
            openResult: { shell.tabs.push(.aiResult($0)) },
            openArtefact: { shell.tabs.push(.artefact($0)) },
            openForm: { shell.tabs.push(Self.formRoute(for: $0)) },
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
                case let .makeForm(kind):
                    makeFormView(kind, in: workspace)
                case let .aiForm(kind):
                    GenerateFormView(
                        store: store, kind: kind, boardState: board, showsFocus: launch.map(Self.showsFocus) ?? false
                    )
                case let .aiResult(id):
                    ResultView(
                        store: store, generationID: id, boardState: board, onMessage: { notices.show($0) },
                        onMissing: { shell.tabs.remove(.aiResult(id)) }
                    )
                case .aiHistory:
                    let make = makeStore(for: workspace)
                    HistoryView(
                        store: make, actions: makeActions,
                        status: rootStatus(savedAt: make.savedAt, offlineRead: make.offlineRead)
                    )
                case .scanRegister:
                    scanView(in: workspace)
                case .checkPaper, .checkPages, .checkScheme, .checkSchemeChooser, .checkResult:
                    checkView(route, in: workspace)
                default:
                    MakeHomeView(
                        store: makeStore(for: workspace), actions: makeActions, startsAtRecent: launch == .makeEmpty
                    )
                }
            }
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                notices.show(message)
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

extension View {
    /// The app's two ways of telling the tutor what happened from anywhere (U33, `docs/design/feedback.md`): the Undo
    /// bar
    /// and the system alert, for every screen and sheet below.
    func tellsTheTutor(toasts: ToastCenter, notices: NoticeCenter) -> some View {
        environment(toasts).environment(notices).notices(notices)
    }
}
