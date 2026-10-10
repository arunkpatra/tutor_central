import Data
import Domain
import Foundation
import Today

/// The background refresh's work (D60, plan decision 15): with the session that is signed in, today's batches not yet
/// closed get their plans made (or a plan already made completed), each artefact kept as it lands, so a refresh iOS
/// stops part-way leaves a plan the next open completes. Signed out, or a day with no batch, it does nothing.
@MainActor struct RefreshHandler {
    let workspace: @MainActor () async -> Workspace?
    let classes: any ClassesRepository
    let students: any StudentsRepository
    let plans: any PlansRepository
    /// The maker for a centre (its copy on this iPhone is the centre's).
    let maker: (UUID) -> PlanMaker
    let now: @Sendable () -> Date
    let calendar: Calendar

    func run() async {
        guard let workspace = await workspace() else { return }
        let centre = workspace.centre.id
        let today = Day(now(), calendar: calendar)
        guard let rooms = try? await classes.classes(centre: centre),
              let people = try? await students.students(centre: centre, period: today.period) else { return }
        let batches = NextClass.classesToday(in: rooms.filter { !$0.isArchived }, on: today, calendar: calendar)
        let maker = maker(centre)
        for batch in batches {
            guard !Task.isCancelled else { return }
            guard await !maker.closed(classID: batch.id, date: today, centre: centre) else { continue }
            let members = people.filter { $0.classID == batch.id && $0.archivedAt == nil }
            if let made = try? await plans.plan(centre: centre, classID: batch.id, date: today) {
                await maker.complete(made, members: members, centre: centre) { _ in }
            } else {
                await maker.make(
                    PlanBatch(classroom: batch, members: members, date: today, centre: centre), choices: nil
                ) { _ in }
            }
        }
    }

    /// The live app's handler: the process's one client and the session it restored.
    static func live(_ deps: Dependencies) -> RefreshHandler {
        RefreshHandler(
            workspace: {
                guard let user = await deps.auth.currentUser() else { return nil }
                return try? await deps.centres.workspace(for: user)
            },
            classes: deps.classes, students: deps.students, plans: deps.plans,
            maker: { centre in
                PlanMaker(
                    plans: deps.plans, textbooks: deps.textbooks, attendance: deps.attendance, ai: deps.ai,
                    cache: PlanCache(centre: centre), now: deps.now, calendar: DayHeading.india
                )
            },
            now: deps.now, calendar: DayHeading.india
        )
    }

    /// What iOS's refresh runs: nothing without the live dependencies (a build without Supabase settings).
    static func runLive() async {
        guard let deps = RootView.live else { return }
        await live(deps).run()
    }
}
