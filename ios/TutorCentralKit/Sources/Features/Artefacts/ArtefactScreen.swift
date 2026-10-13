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
    /// The plans kept on this iPhone: offline the material opens from them.
    let planCache: PlanCache?
    /// A mock's exam and its school (Phase 13).
    let schoolItems: (any SchoolItemsRepository)?
    let schools: (any SchoolsRepository)?
    /// The marks a gap report reads (Phase 13).
    let record: (any RecordRepository)?
    /// The server's PDFs (Phase 18): Share takes the made file when it can be had.
    let serverPDF: ServerPDF?

    public init(
        workspace: Workspace, register: any Register, plans: any PlansRepository, ai: any AIRepository,
        photos: any PhotoStore, now: @escaping @Sendable () -> Date, calendar: Calendar,
        online: @escaping () async -> Bool, planCache: PlanCache? = nil,
        schoolItems: (any SchoolItemsRepository)? = nil, schools: (any SchoolsRepository)? = nil,
        record: (any RecordRepository)? = nil, serverPDF: ServerPDF? = nil
    ) {
        self.record = record
        self.serverPDF = serverPDF
        self.schoolItems = schoolItems
        self.schools = schools
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.photos = photos
        self.now = now
        self.calendar = calendar
        self.online = online
        self.planCache = planCache
    }
}

/// An artefact pushed from its plan line or the student's page: its kind read first, then its screen.
public struct ArtefactScreen: View {
    let artefactID: UUID
    let context: ArtefactsContext
    let actions: ArtefactsActions
    let boardState: ArtefactBoardState?
    @State private var kind: ArtefactKind?
    @State private var found: Artefact?
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
                WorkedExampleView(store: exampleStore(), showsTwo: boardState == .secondStep)
            case .brief?:
                BriefView(store: briefStore())
            case .figure?:
                FigureScreen(store: figureStore())
            case .mock?:
                MockView(store: mockStore(), showsKey: boardState == .key)
            case .gapReport?:
                if let item = found?.schoolItemID, let student = found?.studentID {
                    GapReportView(store: gapStore(item: item, student: student), actions: actions.gapReport)
                }
            case nil where gone:
                SheetView(store: sheetStore(), actions: actions, boardState: nil)
            default:
                Tokens.ground.color.ignoresSafeArea()
            }
        }
        .task {
            if let copy = ArtefactRead.copy(artefactID, cache: context.planCache) {
                found = copy.artefact
                kind = copy.artefact.kind
                return
            }
            let found = try? await ArtefactRead.read(
                artefactID, centre: context.workspace.centre.id, plans: context.plans, cache: context.planCache
            )
            self.found = found?.artefact
            kind = found?.artefact.kind
            gone = found == nil
        }
    }

    private func exampleStore() -> WorkedExampleStore {
        let store = WorkedExampleStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans
        )
        store.planCache = context.planCache
        return store
    }

    private func figureStore() -> FigureStore {
        let store = FigureStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans
        )
        store.planCache = context.planCache
        store.serverPDF = context.serverPDF
        return store
    }

    private func briefStore() -> BriefStore {
        let store = BriefStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans,
            ai: context.ai, now: context.now, calendar: context.calendar
        )
        store.online = context.online
        store.planCache = context.planCache
        store.serverPDF = context.serverPDF
        return store
    }

    private func mockStore() -> MockStore {
        let store = MockStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans,
            ai: context.ai, schoolItems: context.schoolItems, schools: context.schools, now: context.now,
            calendar: context.calendar
        )
        store.online = context.online
        store.planCache = context.planCache
        store.serverPDF = context.serverPDF
        store.onMark = actions.markPaper
        return store
    }

    private func gapStore(item: UUID, student: UUID) -> GapReportStore {
        let store = GapReportStore(
            itemID: item, studentID: student, workspace: context.workspace, register: context.register,
            plans: context.plans, ai: context.ai, record: context.record, schoolItems: context.schoolItems,
            now: context.now, calendar: context.calendar
        )
        store.online = context.online
        store.onUsed = actions.gapUsed
        return store
    }

    private func sheetStore() -> SheetStore {
        let store = SheetStore(
            artefactID: artefactID, workspace: context.workspace, register: context.register, plans: context.plans,
            ai: context.ai, photos: context.photos, now: context.now, calendar: context.calendar
        )
        store.online = context.online
        store.planCache = context.planCache
        store.serverPDF = context.serverPDF
        return store
    }
}
