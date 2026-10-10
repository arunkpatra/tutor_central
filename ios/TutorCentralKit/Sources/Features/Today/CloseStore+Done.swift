import Data
import Domain
import Foundation

/// Done: the marks, the present students' tapped checks and homework, the skill states they move and every student's
/// status, in one write (`close_session`).
extension CloseStore {
    public func done() async -> Bool {
        guard phase != .closing else { return false }
        let before = phase
        let close = makeClose()
        phase = .closing
        if await mustQueue() {
            keepHere(close)
            return true
        }
        do {
            _ = try await attendance.close(close, centre: workspace.centre.id)
        } catch {
            if queue != nil, TransportError.isOffline(error) {
                keepHere(close)
                return true
            }
            phase = before
            message = "The class wasn't closed. Check your connection and try again. Your taps are still here."
            return false
        }
        register.applyTracking(close.track, at: now())
        phase = .closed(at: now())
        return true
    }

    func makeClose() -> SessionClose {
        let marks = Dictionary(uniqueKeysWithValues: students.map {
            ($0.id, $0.present ? AttendanceStatus.present : .absent)
        })
        let present = students.filter(\.present)
        let checks = present.flatMap(checks(of:))
        let homework = present.filter(\.homeworkGiven).map { SessionClose.Homework(studentID: $0.id, artefactID: nil) }
        let states = present.flatMap(states(of:))
        let track = Dictionary(uniqueKeysWithValues: students.map { student in
            (student.id, tracking(student, checks: checks, states: states))
        })
        return SessionClose(
            classID: classID, date: day, marks: marks, checks: checks, homework: homework, track: track,
            states: states
        )
    }

    private func checks(of student: CloseStudent) -> [SessionClose.Check] {
        switch student.checks {
        case let .rows(rows):
            rows.compactMap { row in
                row.tap.map {
                    SessionClose.Check(
                        studentID: student.id, skillID: row.skillID, question: row.question, correct: $0,
                        isPlacement: row.isPlacement
                    )
                }
            }
        case let .placement(subjects):
            subjects.flatMap(\.rows).compactMap { row in
                row.tap.map {
                    SessionClose.Check(
                        studentID: student.id, skillID: row.skillID, question: row.question, correct: $0,
                        isPlacement: true
                    )
                }
            }
        default:
            []
        }
    }

    /// A check moves its skill by `SkillProgress.after` with the previous check on it; the placement secures the
    /// chapters before the first wrong. A tap unchanged since the close was kept moves nothing again.
    private func states(of student: CloseStudent) -> [SkillStateChange] {
        let skills = skills[student.id] ?? []
        switch student.checks {
        case let .rows(rows):
            return rows.compactMap { row in
                guard let correct = row.tap, correct != row.recorded,
                      let skill = skills.first(where: { $0.id == row.skillID }) else { return nil }
                let previous = history.filter { $0.skillID == row.skillID }.max { $0.at < $1.at }?.correct
                guard let state = SkillProgress.after(skill.state, correct: correct, previousCorrect: previous),
                      state != skill.state else { return nil }
                return SkillStateChange(skillID: skill.id, state: state)
            }
        case let .placement(subjects):
            return subjects.flatMap { Placement.changes($0, chapters: chapters[student.id] ?? [], skills: skills) }
        default:
            return []
        }
    }

    /// The status with today's checks, homework and attendance added (an absence counts too).
    private func tracking(
        _ student: CloseStudent, checks: [SessionClose.Check], states: [SkillStateChange]
    ) -> SessionClose.Track {
        let at = now()
        let moved = Dictionary(states.map { ($0.skillID, $0.state) }) { _, last in last }
        let after = (skills[student.id] ?? []).map { skill in
            var changed = skill
            if let state = moved[skill.id] {
                changed.state = state
                changed.stateAt = at
            }
            return changed
        }
        let today = checks.filter { $0.studentID == student.id }.map { check in
            CheckRecord(
                id: UUID(), studentID: student.id, skillID: check.skillID, sessionID: nil, question: check.question,
                correct: check.correct, at: at, isPlacement: check.isPlacement
            )
        }
        let given = student.present && student.homeworkGiven
            ? [HomeworkRecord(id: UUID(), studentID: student.id, sessionID: UUID(), givenAt: at, status: .given)] : []
        let since = Day(
            calendar.date(byAdding: .day, value: -TrackingRules.absenceWindowDays, to: at) ?? at, calendar: calendar
        )
        let absences = sessions.count { $0.date >= since && $0.date < day && $0.marks[student.id] == .absent }
            + (student.present ? 0 : 1)
        let tracking = TrackingRules.evaluate(TrackingInput(
            checks: history.filter { $0.studentID == student.id } + today, absences: absences,
            homework: homeworkHistory.filter { $0.studentID == student.id } + given, skills: after,
            chapters: chapters[student.id] ?? [], classLevel: register.student(student.id)?.classLevel, now: at,
            calendar: calendar
        ))
        return SessionClose.Track(status: tracking.status, reasons: tracking.reasons)
    }
}
