import Data
import Domain
import Foundation
import Today

/// The server's plan job as the boards see it (Phase 18): live on P10-Today-Planning and P18-Today-Plan-Making, failed
/// on the failed card, live with the plan written and no material yet on the close's cards; elsewhere a request is
/// answered at once by the plan the rules make, its material kept from the samples.
extension Fixtures {
    struct PlanServer {
        let plans: FakePlansRepository
        let preview: PlanPreview
        let students: [Student]
        let classes: [Classroom]

        init(
            plans: FakePlansRepository, textbooks: any TextbooksRepository, attendance: any AttendanceRepository,
            schoolItems: any SchoolItemsRepository, students: [Student], classes: [Classroom],
            now: @escaping @Sendable () -> Date
        ) {
            self.plans = plans
            preview = PlanPreview(
                plans: plans, textbooks: textbooks, attendance: attendance, schoolItems: schoolItems, cache: nil,
                now: now, calendar: DayHeading.india
            )
            self.students = students
            self.classes = classes
        }
    }

    @MainActor static func jobs(for state: LaunchState, server: PlanServer) -> FakeJobsRepository {
        let at = clock(for: state)
        let evening = FakeClassesRepository.evening.id
        switch state {
        case .todayPlanning:
            return FakeJobsRepository(planJobs: [evening: JobStatus(id: UUID(), state: .running, createdAt: at)])
        case .todayPlanMaking:
            let started = at.addingTimeInterval(-5 * 60)
            return FakeJobsRepository(planJobs: [evening: JobStatus(id: UUID(), state: .running, createdAt: started)])
        case .todayPlanFailed:
            return FakeJobsRepository(planJobs: [
                evening: JobStatus(id: UUID(), state: .failed, createdAt: at, finishedAt: at),
            ])
        default:
            let jobs = FakeJobsRepository(now: { at })
            // Dev's science checks and Riya's placement still to come on the close's cards.
            let material = state != .closeCards
            jobs.onPlanRequest = { classID, date, choices in
                await serve(server, classID: classID, date: date, choices: choices, material: material)
            }
            return jobs
        }
    }

    /// The plan job's work done in place: the rules' groups for the batch and day, written and filled.
    @MainActor private static func serve(
        _ server: PlanServer, classID: UUID, date: Day, choices: PlanChoices?, material: Bool
    ) async -> JobStatus.State {
        guard let classroom = server.classes.first(where: { $0.id == classID }) else { return .failed }
        let members = StudentQuery.apply(
            server.students, classes: server.classes, search: "", filter: .classroom(classID), sort: .name
        )
        let centre = meeraWorkspace.centre.id
        let batch = PlanBatch(classroom: classroom, members: members, date: date, centre: centre)
        guard let draft = try? await server.preview.draft(batch, choices: choices) else { return .failed }
        let pairs = members.compactMap { member in member.classLevel.map { (member.id, $0) } }
        let levels = Dictionary(pairs) { first, _ in first }
        guard await (try? server.plans.serve(draft, levels: levels, material: material, centre: centre)) != nil
        else { return .failed }
        return material ? .done : .running
    }
}
