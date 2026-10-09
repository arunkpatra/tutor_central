import Data
import Domain
import Foundation

/// Tell parent (P4-Absence-Alert): the sheet's words and the logged link; offline the log waits here (D39).
public extension AttendanceStore {
    /// The sheet behind Tell parent; nil once that parent was told for the day.
    func alert(for studentID: UUID) -> AbsenceAlert? {
        guard let saved, saved.marks[studentID] == .absent, let student = register.student(studentID),
              absentRows.first(where: { $0.student.id == studentID })?.told == nil else { return nil }
        let text = AbsenceMessage(
            parentName: student.parentName, studentName: student.name,
            className: register.classroom(saved.classID)?.name, day: saved.date, today: today,
            tutorName: workspace.profile.displayName, centreName: workspace.centre.name
        ).text
        let line = student.parentPhone
            .map { [student.parentName, $0.display].compactMap(\.self).joined(separator: " · ") }
        let when = saved.date == today ? "today" : "on \(saved.date.shortWeekdayText)"
        return AbsenceAlert(
            student: student,
            headline: "\(student.firstName) was absent \(when)",
            parentLine: line ?? "Add the parent's number first",
            text: text,
            url: student.parentPhone.map { AbsenceMessage.whatsAppURL(phone: $0, text: text) }
        )
    }

    /// Logs the alert (D3), then hands back the link to open. Nil, with a toast, when it could not be logged.
    func tell(_ studentID: UUID) async -> URL? {
        guard let alert = alert(for: studentID), let url = alert.url, let day = saved?.date else { return nil }
        if await mustQueue(.absenceLog) {
            keepAlertHere(alert.student, about: day)
            return url
        }
        do {
            try await told.insert(
                messages.logAbsence(centre: workspace.centre.id, studentID: studentID, about: day), at: 0
            )
            lastSavedAt = now()
            return url
        } catch {
            if queue != nil, TransportError.isOffline(error) {
                // WhatsApp works offline; the log waits on this iPhone (D39).
                keepAlertHere(alert.student, about: day)
                return url
            }
            message = "Couldn't open WhatsApp. Check your connection and try again."
            canRetry = false
            return nil
        }
    }
}
