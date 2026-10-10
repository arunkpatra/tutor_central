import Artefacts
import Data
import DesignSystem
import Domain
import SwiftUI

/// The artefacts' wiring (V2): a sheet, a worked example or a brief pushed from a plan line or a student's page.
extension RootView {
    @ViewBuilder func artefactView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            ArtefactScreen(
                artefactID: id,
                context: ArtefactsContext(
                    workspace: workspace, register: register(for: workspace), plans: deps.plans, ai: deps.ai,
                    photos: deps.photos, now: deps.now, calendar: DayHeading.india,
                    online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                ),
                actions: ArtefactsActions(openArtefact: { shell.tabs.push(.artefact($0)) }),
                boardState: launch.flatMap(Self.artefactBoardState)
            )
        }
    }

    /// The artefacts' launch states on Today's stack: Group 1's homework sheet, the tutor's own, Group 1's worked
    /// example, the brief, a figure board's figure.
    static func artefactRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .sheetOwn: [.artefact(Fixtures.ownSheet)]
        case .workedExample: [.artefact(Fixtures.groupOneExample)]
        case .brief: [.artefact(Fixtures.brief)]
        case _ where Fixtures.figureStates[state] != nil: [.artefact(FakePlansRepository.figureID)]
        case _ where Fixtures.sheetStates.contains(state): [.artefact(Fixtures.groupOneSheet)]
        default: nil
        }
    }

    static func artefactBoardState(_ state: LaunchState) -> ArtefactBoardState? {
        switch state {
        case .sheetKey: .key
        case .sheetBoard: .board
        case .sheetRegenerate: .reasons
        case .sheetRegenerating: .regenerating
        case .sheetOwnMenu: .ownMenu
        case .workedExample: .secondStep
        default: nil
        }
    }
}
