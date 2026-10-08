import AITools
import DesignSystem
import Domain
import Foundation
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
