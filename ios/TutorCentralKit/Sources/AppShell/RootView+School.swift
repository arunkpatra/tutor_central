import Data
import DesignSystem
import Domain
import School
import SwiftUI

/// The School tab's wiring (Phase 13): the root, "Check what was read", an item's page. The share hand-off is
/// `ShellState.inboxHandoff`.
extension RootView {
    /// One School tab per centre (`ShellState.school`), so a tab switch keeps its segment and day.
    func schoolStore(for workspace: Workspace) -> SchoolStore {
        if let store = shell.school {
            return store
        }
        let store = SchoolStore(
            workspace: workspace, items: deps.schoolItems, register: register(for: workspace), schools: deps.schools,
            cache: deps.cachesLists ? SchoolCache(centre: workspace.centre.id, directory: deps.filesDirectory) : nil,
            now: deps.now, calendar: DayHeading.india
        )
        shell.school = store
        return store
    }

    var schoolActions: SchoolActions {
        SchoolActions(
            openItem: { shell.tabs.push(.schoolItem($0)) },
            read: { shell.tabs.push(.schoolRead($0)) },
            askParents: { shell.tabs.push(.schoolAsk) }
        )
    }

    @ViewBuilder var schoolView: some View {
        if case let .ready(workspace) = session.state {
            let store = schoolStore(for: workspace)
            SchoolView(
                store: store, actions: schoolActions, boardState: launch.flatMap(Self.schoolBoardState),
                status: { rootStatus(savedAt: $0, offlineRead: $1) }
            )
        }
    }

    @ViewBuilder func schoolScreen(_ route: Route) -> some View {
        if case let .ready(workspace) = session.state {
            switch route {
            case let .schoolRead(source):
                ReadScreen(
                    store: readStore(source, workspace: workspace),
                    boardState: launch == .schoolConfirmEdit ? .editFirst : nil,
                    leave: { shell.tabs.remove(route) },
                    done: { items in
                        shell.tabs.remove(route)
                        schoolItemsAdded(items, workspace: workspace)
                    }
                )
            case let .schoolItem(id):
                ItemScreen(
                    store: itemStore(id, workspace: workspace),
                    boardState: nil,
                    back: { shell.tabs.remove(route) }
                )
            default:
                EmptyView()
            }
        }
    }

    private func readStore(_ source: ReadSource, workspace: Workspace) -> ReadStore {
        let leave: (@MainActor () -> Void)? = if case let .shared(read) = source {
            { try? SharedInbox.live()?.remove(id: read.id) }
        } else {
            nil
        }
        return ReadStore(
            source: source, workspace: workspace, items: deps.schoolItems, ai: deps.ai,
            register: register(for: workspace),
            schools: deps.schools, photos: deps.photos, leaveInbox: leave, now: deps.now, calendar: DayHeading.india,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
        )
    }

    private func itemStore(_ id: UUID, workspace: Workspace) -> ItemStore {
        let store = ItemStore(
            itemID: id, workspace: workspace, items: deps.schoolItems, register: register(for: workspace),
            schools: deps.schools, photos: deps.photos, now: deps.now, calendar: DayHeading.india,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
        )
        store.onChanged = { students in
            shell.schoolItemsChanged?(students)
            Task { await shell.school?.refresh() }
        }
        return store
    }

    /// Items added on "Check what was read": the tab reads them, and the plan hears whom they reach (decision 16).
    private func schoolItemsAdded(_ items: [SchoolItem], workspace: Workspace) {
        let students = register(for: workspace).activeStudents
        let reached = Set(items.flatMap { SchoolItemRules.students(for: $0, in: students).map(\.id) })
        shell.schoolItemsChanged?(reached)
        Task { await shell.school?.refresh() }
    }
}

/// "Check what was read" with its store kept for the life of the push (a rebuild must not read again).
struct ReadScreen: View {
    @State private var store: ReadStore
    let boardState: ReadBoardState?
    let leave: () -> Void
    let done: ([SchoolItem]) -> Void

    init(
        store: ReadStore, boardState: ReadBoardState?, leave: @escaping () -> Void,
        done: @escaping ([SchoolItem]) -> Void
    ) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.leave = leave
        self.done = done
    }

    var body: some View {
        ReadView(store: store, boardState: boardState, leave: leave, done: done)
    }
}

/// An item's page with its store kept for the life of the push.
struct ItemScreen: View {
    @State private var store: ItemStore
    let boardState: ItemBoardState?
    let back: () -> Void

    init(store: ItemStore, boardState: ItemBoardState?, back: @escaping () -> Void) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.back = back
    }

    var body: some View {
        ItemView(store: store, boardState: boardState, back: back)
    }
}
