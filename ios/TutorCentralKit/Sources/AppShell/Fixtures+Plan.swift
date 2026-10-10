import Data
import Domain
import Foundation

/// The 10.3 boards' plan (P10-Today-Plan and its states): the Evening batch on Wednesday 7 October in three groups,
/// Group 1 · Chemical reactions for Dev, Meher and Nikhil, Group 2 · Parts and wholes for Riya, Group 3 · Reading for
/// Sahil, the material made (the figures are illustrative).
extension Fixtures {
    static let planStates: Set<LaunchState> = .init([
        .today, .todayScrolled, .todayPlanning, .todayLineMenu, .todayPlanChanged, .todayPlanChange,
        .todayAfterClose,
    ]).union(sheetStates)

    /// The sheet's states (P10-Sheet and its forms), over the boards' plan.
    static let sheetStates: Set<LaunchState> = [.sheet, .sheetKey, .sheetBoard]

    /// Group 1's homework sheet in the boards' plan.
    static let groupOneSheet = UUID(uuidString: "abababab-0000-0000-0001-000000000012")!

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
        switch state {
        case .todayPlanning:
            // P10-Today-Planning: the plan is still being written.
            let plans = FakePlansRepository()
            plans.makeDelay = .seconds(3600)
            return plans
        case _ where planStates.contains(state):
            return FakePlansRepository.evening(changed: state == .todayPlanChanged, done: state == .todayAfterClose)
        default:
            return FakePlansRepository()
        }
    }
}
