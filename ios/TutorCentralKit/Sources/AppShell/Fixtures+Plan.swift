import Data
import Domain
import Foundation
import UIKit

/// The 10.3 boards' plan (P10-Today-Plan and its states): the Evening batch on Wednesday 7 October in three groups,
/// Group 1 · Chemical reactions for Dev, Meher and Nikhil, Group 2 · Parts and wholes for Riya, Group 3 · Reading for
/// Sahil, the material made (the figures are illustrative).
extension Fixtures {
    static let planStates: Set<LaunchState> = .init([
        .today, .todayScrolled, .todayPlanning, .todayPlanMaking, .todayPlanFailed, .todayLineMenu, .todayPlanChanged,
        .todayPlanChange,
        .todayAfterClose, .workedExample, .brief, .briefAgain, .todayRevision,
    ]).union(sheetStates).union(figureStates.keys).union(mathsStates)

    /// Phase 20's material states over the boards' plan with its maths groups (P20-*); the mock's is apart.
    static let mathsStates: Set<LaunchState> = [
        .sheetMathsTo5, .sheetMathsFrom6, .sheetBoardMaths, .workedExampleMaths,
    ]

    /// The figure boards' states and their templates (P10-Figure-*).
    static let figureStates: [LaunchState: FigureSpec.Kind] = [
        .figureNumberLine: .numberLine, .figureFractionBar: .fractionBar, .figurePlaceValue: .placeValue,
        .figureUnitCircle: .unitCircle, .figureTriangle: .triangle, .figureCell: .labelledCell,
        .figureFoodChain: .foodChain,
    ]

    /// The sheet's states (P10-Sheet and its forms), over the boards' plan.
    static let sheetStates: Set<LaunchState> = [
        .sheet, .sheetKey, .sheetBoard, .sheetRegenerate, .sheetRegenerating, .sheetOwnMenu, .sheetOwn,
    ]

    /// The tutor's own sheet in place of Group 1's (P10-Sheet-Own) and its photo.
    static let ownSheet = UUID(uuidString: "abababab-0000-0000-0001-000000000099")!
    static let ownPhotoPath = "\(meeraWorkspace.centre.id.uuidString.lowercased())/own/sheet-1.jpg"

    @MainActor static func photos(for state: LaunchState) -> FakePhotoStore {
        let photos = FakePhotoStore()
        if state == .sheetOwn {
            photos.images[ownPhotoPath] = sheetPhoto()
        }
        return photos
    }

    /// A photographed sheet as the board draws it: a page with its lines.
    static func sheetPhoto() -> Data {
        let size = CGSize(width: 900, height: 1200)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: 0.93, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(white: 0.62, alpha: 1).setFill()
            for (line, width) in [0.7, 0.86, 0.6, 0.9, 0.74, 0.64, 0.82, 0.56].enumerated() {
                context.fill(CGRect(x: 72, y: 90 + CGFloat(line) * 66, width: (size.width - 144) * width, height: 18))
            }
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    /// Group 1's homework sheet, its worked example and the brief in the boards' plan.
    static let groupOneSheet = UUID(uuidString: "abababab-0000-0000-0001-000000000012")!
    static let groupOneExample = UUID(uuidString: "abababab-0000-0000-0001-000000000014")!
    static let brief = UUID(uuidString: "abababab-0000-0000-0001-000000000005")!

    /// The Evening batch's five with the boards' statuses: Dev not on track, Meher on track, Nikhil to watch, Riya not
    /// known yet, Sahil on track.
    static let planStudents: [Student] = FakeStudentsRepository.eveningSeed.map { student in
        var marked = student
        switch student.id {
        case FakeStudentsRepository.dev: marked.trackStatus = .notOnTrack
        case FakeStudentsRepository.meher, FakeStudentsRepository.sahil: marked.trackStatus = .onTrack
        case FakeStudentsRepository.nikhil: marked.trackStatus = .watch
        default: break
        }
        return marked
    }

    @MainActor static func plans(for state: LaunchState) -> FakePlansRepository {
        if let make = makePlans(for: state) ?? jobPlans(for: state) ?? mathsPlans(for: state) ??
            setAsidePlans(for: state) {
            return make
        }
        switch state {
        case .studentMessages:
            return FakePlansRepository(artefacts: devNotes, now: noteDayClock)
        case .sheetOwn:
            return FakePlansRepository.evening(ownSheet: ownSheet, photoPath: ownPhotoPath)
        case _ where figureStates[state] != nil:
            return FakePlansRepository.figure(figureStates[state] ?? .numberLine)
        case _ where lastDaysStates.contains(state):
            return FakePlansRepository(artefacts: examArtefacts(for: state))
        case .mock, .mockKey, .mockAgain, .make, .aiHistory:
            return FakePlansRepository(
                artefacts: [.mock, .mockKey, .mockAgain]
                    .contains(state) ? [FakePlansRepository.boardMock] : FakePlansRepository
                    .madeRecent
            )
        case .closeCards, .todayRevision:
            // P13-Today-Revision: made on the board's moment from the exam nine days out.
            return FakePlansRepository()
        case _ where planStates.contains(state) || closeStates.contains(state):
            return FakePlansRepository.evening(changed: state == .todayPlanChanged, done: state == .todayAfterClose)
        default:
            return FakePlansRepository()
        }
    }

    /// Phase 20's material: the boards' plan with its maths groups, or Dev's maths mock alone.
    @MainActor static func mathsPlans(for state: LaunchState) -> FakePlansRepository? {
        if mathsStates.contains(state) {
            return FakePlansRepository.eveningMaths()
        }
        return state == .mockMaths ? FakePlansRepository.mathsMock() : nil
    }

    /// The plan job's states: none written yet (its job live, P10-Today-Planning), none for a failed job, or the plan
    /// made at 06:00 with Group 1's set and sheet alone (P18-Today-Plan-Making).
    @MainActor static func jobPlans(for state: LaunchState) -> FakePlansRepository? {
        switch state {
        case .todayPlanning, .todayPlanFailed: FakePlansRepository()
        case .todayPlanMaking: FakePlansRepository.eveningMaking()
        default: nil
        }
    }

    /// Make's states: today's plan for the groups and Make's own artefacts; Check a paper's intro: the exam's mock and
    /// Make's.
    @MainActor static func makePlans(for state: LaunchState) -> FakePlansRepository? {
        if makeStates.contains(state) {
            let evening = FakePlansRepository.evening()
            return FakePlansRepository(
                plans: evening.plans, artefacts: FakePlansRepository.boardArtefacts + FakePlansRepository.madeRecent,
                now: evening.now
            )
        }
        if [.checkIntro, .checkSchemeChooser, .checkIntroMock].contains(state) {
            return FakePlansRepository(artefacts: FakePlansRepository.lastDaysArtefacts + FakePlansRepository
                .madeRecent)
        }
        return nil
    }
}
