import Artefacts
import Data
import DesignSystem
import Domain
import Make
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
                    online: { [connectivity = deps.connectivity] in await connectivity.isOnline },
                    planCache: deps.cachesLists
                        ? PlanCache(centre: workspace.centre.id, directory: deps.filesDirectory) : nil,
                    schoolItems: deps.schoolItems, schools: deps.schools, record: deps.record,
                    serverPDF: deps.serverFiles(workspace.centre.id).map {
                        ServerPDF(
                            files: $0, centre: workspace.centre.id,
                            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                        )
                    },
                    feedback: deps.feedback
                ),
                actions: ArtefactsActions(
                    openArtefact: { shell.tabs.push(.artefact($0)) },
                    markPaper: { mark in
                        let visit = UUID()
                        shell.checkPresets[visit] = CheckPreset(mark)
                        shell.tabs.push(.checkPaper(visit))
                    },
                    gapReport: GapReportActions(openToday: { shell.openToday(batch: $0) }),
                    gapUsed: { student in
                        shell.recordChanged += 1
                        shell.schoolItemsChanged?([student])
                    }
                ),
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
        case .brief, .briefAgain: [.artefact(Fixtures.brief)]
        case .mock, .mockKey, .mockAgain: [.artefact(FakePlansRepository.boardMockID)]
        case _ where Fixtures.figureStates[state] != nil: [.artefact(FakePlansRepository.figureID)]
        case _ where Fixtures.sheetStates.contains(state): [.artefact(Fixtures.groupOneSheet)]
        default: nil
        }
    }

    /// Phase 20's material on Today's stack: the two sheets, the worked example, Dev's maths mock, the brief.
    static func mathsRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .sheetMathsTo5: [.artefact(FakePlansRepository.mathsSheetTo5)]
        case .sheetMathsFrom6, .sheetBoardMaths: [.artefact(FakePlansRepository.mathsSheetFrom6)]
        case .workedExampleMaths: [.artefact(FakePlansRepository.mathsExample)]
        case .briefMaths: [.artefact(FakePlansRepository.mathsBrief)]
        case .mockMaths: [.artefact(FakePlansRepository.mathsMockID)]
        default: nil
        }
    }

    static func artefactBoardState(_ state: LaunchState) -> ArtefactBoardState? {
        switch state {
        case .sheetKey, .mockKey: .key
        case .sheetBoard: .board
        case .sheetBoardMaths: .boardWithKey
        case .sheetRegenerate, .briefAgain, .mockAgain: .reasons
        case .sheetRegenerating: .regenerating
        case .sheetOwnMenu: .ownMenu
        case .workedExample, .workedExampleMaths: .secondStep
        case .briefMaths: .atExample
        default: nil
        }
    }
}
