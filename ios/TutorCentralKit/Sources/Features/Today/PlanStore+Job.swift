import Domain
import Foundation

/// The plan's job on screen (P18-Today-Plan-Making): the line while the material is made, and the reads while the job
/// is live.
extension PlanStore {
    /// Under "Today's plan" while the plan is shown and a mark is on its way (P18-Today-Plan-Making).
    public var madeLine: String? {
        guard case let .planning(plan?) = state,
              groups.contains(where: { $0.marks.contains { $0.state == .onItsWay } }) else { return nil }
        let made = QueuedChange.clock(plan.madeAt, calendar: calendar)
        let rest = "The sheets and checks are still being made; each mark turns green when it is ready."
        let parts = calendar.dateComponents([.hour, .minute], from: plan.madeAt)
        // A plan made again after the batch began is not "before the batch".
        guard let start = register.classroom(classID)?.startTime,
              let at = TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0), at < start
        else { return "Made at \(made). \(rest)" }
        return "Made at \(made), before the batch. \(rest)"
    }

    /// Reads again every ten seconds while the job is live and the app is in front; a push ends the wait sooner (the
    /// next open reads at once).
    func follow() {
        guard polling == nil else { return }
        followed += 1
        let mine = followed
        polling = Task { [weak self] in
            while !Task.isCancelled {
                guard let pause = self?.pause, await (try? pause()) != nil, let self, !Task.isCancelled,
                      inFront(), await online(), let classroom = register.classroom(classID) else { break }
                await read(classroom, asking: false)
                guard job?.isLive == true else { break }
            }
            // A follow cancelled and started again keeps the new one.
            if self?.followed == mine {
                self?.polling = nil
            }
        }
    }
}
