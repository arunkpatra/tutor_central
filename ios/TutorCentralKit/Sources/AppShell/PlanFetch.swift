import Data
import Domain
import Foundation

/// A plan's background push (`fetch: "plan"`, plan/phase-18-plan.md decision 17): with the session signed in, today's
/// plan for every batch is read into the copy on this iPhone, so Today opens with it at once, offline too. Signed out,
/// it does nothing. iOS gives it 30 seconds.
@MainActor struct PlanFetch {
    let workspace: @MainActor () async -> Workspace?
    let classes: any ClassesRepository
    let plans: any PlansRepository
    /// The centre's copy (its files are the centre's).
    let cache: (UUID) -> PlanCache
    let now: @Sendable () -> Date
    let calendar: Calendar

    /// True when every batch's read answered (a plan or none); false when signed out or a read failed.
    func run() async -> Bool {
        guard let workspace = await workspace() else { return false }
        let centre = workspace.centre.id
        let today = Day(now(), calendar: calendar)
        guard let rooms = try? await classes.classes(centre: centre) else { return false }
        let batches = NextClass.classesToday(in: rooms.filter { !$0.isArchived }, on: today, calendar: calendar)
        let cache = cache(centre)
        return await withTaskGroup(of: PlanRecord??.self, returning: Bool.self) { group in
            for batch in batches {
                group.addTask { [plans] in
                    // nil: the read failed; .some(nil): the batch has no plan yet.
                    try? await plans.plan(centre: centre, classID: batch.id, date: today)
                }
            }
            var answered = true
            for await read in group {
                switch read {
                case let .some(.some(plan)): cache.keep(plan, at: now())
                case .some(.none): break
                case .none: answered = false
                }
            }
            return answered
        }
    }

    /// iOS gives a background push 30 seconds and a stalled read takes about 20 s to fail: `run` raced against a deadline,
    /// false when the deadline comes first (its reads cancelled; a batch already read stays in the copy).
    func run(within deadline: Duration) async -> Bool {
        let answer = Answer()
        return await withCheckedContinuation { continuation in
            answer.continuation = continuation
            let work = Task { answer.give(await run()) }
            Task {
                try? await Task.sleep(for: deadline)
                work.cancel()
                answer.give(false)
            }
        }
    }

    /// The first of the run and the deadline answers; the other is dropped.
    @MainActor private final class Answer {
        var continuation: CheckedContinuation<Bool, Never>?

        func give(_ value: Bool) {
            continuation?.resume(returning: value)
            continuation = nil
        }
    }

    /// Whether a push is a plan's fetch.
    static func asks(_ userInfo: [AnyHashable: Any]) -> Bool {
        userInfo["fetch"] as? String == "plan"
    }

    /// The live app's fetch: the process's one client and the session it restored.
    static func live(_ deps: Dependencies) -> PlanFetch {
        PlanFetch(
            workspace: {
                guard let user = await deps.auth.currentUser() else { return nil }
                return try? await deps.centres.workspace(for: user)
            },
            classes: deps.classes, plans: deps.plans, cache: { PlanCache(centre: $0) }, now: deps.now,
            calendar: DayHeading.india
        )
    }

    /// What the app delegate runs for a background push: nothing without the live dependencies.
    static func runLive() async -> Bool {
        guard let deps = RootView.live else { return false }
        // Five seconds of iOS's thirty kept for the answer to reach it.
        return await live(deps).run(within: .seconds(25))
    }
}
