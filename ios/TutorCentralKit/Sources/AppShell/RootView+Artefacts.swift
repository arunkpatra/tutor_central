import Artefacts
import Data
import DesignSystem
import Domain
import SwiftUI

/// The artefacts' wiring (V2): a sheet pushed from a plan line or a student's page.
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
                boardState: launch.flatMap(Self.sheetBoardState)
            )
        }
    }

    /// The sheet's launch states on Today's stack: Group 1's homework sheet.
    static func artefactRoutes(for state: LaunchState) -> [Route]? {
        guard Fixtures.sheetStates.contains(state) else { return nil }
        return [.artefact(state == .sheetOwn ? Fixtures.ownSheet : Fixtures.groupOneSheet)]
    }

    static func sheetBoardState(_ state: LaunchState) -> SheetBoardState? {
        switch state {
        case .sheetKey: .key
        case .sheetBoard: .board
        case .sheetRegenerate: .reasons
        case .sheetRegenerating: .regenerating
        case .sheetOwnMenu: .ownMenu
        default: nil
        }
    }
}
