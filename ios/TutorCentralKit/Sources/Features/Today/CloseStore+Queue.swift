import Data
import Domain
import Foundation

/// The close offline (D39): kept on this iPhone as one change and sent with the queue's next run, as Attendance's save.
extension CloseStore {
    /// Offline, or a close or attendance change already waits (so an older one can never overtake a newer one).
    func mustQueue() async -> Bool {
        guard let queue else { return false }
        if queue.pending.has(kind: .close) || queue.pending.has(kind: .attendance) {
            return true
        }
        return await !online()
    }

    /// The close kept here: the queue holds it, the register takes the statuses, Today's hero reads it closed.
    func keepHere(_ close: SessionClose) {
        let at = now()
        queue?.add(QueuedChange(
            kind: .close(
                close: close, className: batchName, present: close.marks.values.count { $0 == .present },
                total: close.marks.count
            ),
            madeAt: at
        ))
        register.applyTracking(close.track, at: at)
        phase = .savedHere(at: at)
    }
}
