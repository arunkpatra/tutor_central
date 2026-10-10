import Data
import DesignSystem
import Domain
import SwiftUI

/// What an artefact's screen needs: the centre, the register and the repositories (AppShell's).
public struct ArtefactsContext {
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let ai: any AIRepository
    let photos: any PhotoStore
    let now: @Sendable () -> Date
    let calendar: Calendar
    let online: () async -> Bool

    public init(
        workspace: Workspace, register: any Register, plans: any PlansRepository, ai: any AIRepository,
        photos: any PhotoStore, now: @escaping @Sendable () -> Date, calendar: Calendar,
        online: @escaping () async -> Bool
    ) {
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.photos = photos
        self.now = now
        self.calendar = calendar
        self.online = online
    }
}

/// An artefact pushed from its plan line or the student's page: its kind read first, then its screen.
public struct ArtefactScreen: View {
    let artefactID: UUID
    let context: ArtefactsContext
    let actions: ArtefactsActions
    let boardState: ArtefactBoardState?
    @State private var kind: ArtefactKind?
    @State private var gone = false

    public init(
        artefactID: UUID, context: ArtefactsContext, actions: ArtefactsActions, boardState: ArtefactBoardState? = nil
    ) {
        self.artefactID = artefactID
        self.context = context
        self.actions = actions
        self.boardState = boardState
    }

    public var body: some View {
        Group {
            switch kind {
            case .sheet?:
                SheetView(store: sheetStore(), actions: actions, boardState: boardState)
            case .workedExample?:
                WorkedExampleView(
                    store: WorkedExampleStore(
                        artefactID: artefactID, workspace: context.workspace, register: context.register,
                        plans: context.plans
                    ),
                    showsTwo: boardState == .secondStep
                )
            case .brief?:
                BriefView(store: briefStore())
            case nil where gone:
                SheetView(store: sheetStore(), actions: actions, boardState: nil)
            default:
                Tokens.ground.color.ignoresSafeArea()
            }
        }
        .task {
            let found = try? await context.plans.artefact(id: artefactID, centre: context.workspace.centre.id)
            kind = found?.kind
            gone = found == nil
        }
    }

    private func briefStore() -> BriefStore {
        let store = BriefStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans,
            ai: context.ai, now: context.now, calendar: context.calendar
        )
        store.online = context.online
        return store
    }

    private func sheetStore() -> SheetStore {
        let store = SheetStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans,
            ai: context.ai, photos: context.photos, now: context.now, calendar: context.calendar
        )
        store.online = context.online
        return store
    }
}
