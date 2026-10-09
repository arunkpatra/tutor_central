import Data
import Domain
import Foundation

/// The two attendance writes that work offline (D39): a save and the absence alert's log, kept on this iPhone and
/// sent in order when the network returns.
extension AttendanceStore {
    /// Offline, or a change of this kind already waits (so an older one can never overtake a newer one).
    func mustQueue(_ kind: QueuedChangeCase) async -> Bool {
        guard let queue else { return false }
        if queue.pending.has(kind: kind) {
            return true
        }
        return await !online()
    }

    /// The save kept here: the queue holds it, the screen reads saved with the due banner and Tell parent live.
    func keepHere(_ marks: [UUID: AttendanceStatus]) {
        let at = now()
        let present = marks.values.count { $0 == .present }
        queue?.add(QueuedChange(
            kind: .attendance(
                classID: draft.classID, className: register.classroom(draft.classID)?.name ?? "All students",
                date: draft.date, marks: marks, present: present, total: marks.count
            ),
            madeAt: at
        ))
        let session = AttendanceSession(
            id: saved?.id ?? UUID(), classID: draft.classID, date: draft.date, savedAt: at, marks: marks
        )
        saved = session
        sessions.removeAll { $0.date == session.date && $0.classID == session.classID }
        sessions.insert(session, at: 0)
        phase = .savedHere(at: at)
        lastSavedAt = at
    }

    /// After the queue sent or dropped a change: the shown class and day read again from the server (a draft
    /// with unsaved toggles is left alone).
    public func reload() async {
        guard opened, phase != .saving, !draft.isChanged(from: saved, members: members) else { return }
        loadedMonth = nil
        await open(classID: draft.classID, date: draft.date)
    }

    /// The alert's log kept here; the row reads told, as it would online.
    func keepAlertHere(_ student: Student, about day: Day) {
        let at = now()
        queue?.add(QueuedChange(
            kind: .absenceLog(studentID: student.id, studentName: student.name, about: day), madeAt: at
        ))
        told.insert(AbsenceLog(studentID: student.id, openedAt: at, aboutDate: day), at: 0)
        lastSavedAt = at
    }
}
