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

    /// This batch's close for today still waiting in the queue, as a session with its checks and homework.
    func keptHere() -> KeptClose? {
        guard let change = queue?.pending.changes.last(where: { change in
            if case let .close(close, _, _, _) = change.kind {
                close.classID == classID && close.date == day
            } else {
                false
            }
        }), case let .close(close, _, _, _) = change.kind else { return nil }
        let session = AttendanceSession(
            id: change.id, classID: classID, date: day, savedAt: change.madeAt, marks: close.marks,
            closedAt: change.madeAt
        )
        let checks = close.checks.map { check in
            CheckRecord(
                id: UUID(), studentID: check.studentID, skillID: check.skillID, sessionID: change.id,
                question: check.question, correct: check.correct, at: change.madeAt, isPlacement: check.isPlacement
            )
        }
        let homework = close.homework.map { item in
            HomeworkRecord(
                id: UUID(), studentID: item.studentID, sessionID: change.id, givenAt: change.madeAt, status: .given
            )
        }
        return KeptClose(session: session, checks: checks, homework: homework)
    }
}

/// A close kept on this iPhone, read back as the server would answer it.
struct KeptClose {
    let session: AttendanceSession
    let checks: [CheckRecord]
    let homework: [HomeworkRecord]
}
