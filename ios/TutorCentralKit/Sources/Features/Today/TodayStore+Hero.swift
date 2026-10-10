import Domain
import Foundation

/// A closed session's counts for the hero's line: the checks, how many right, the homework given.
struct CloseCounts: Hashable, Sendable {
    var checks = 0
    var right = 0
    var homework = 0
}

/// A batch closed today: its session (the server's, or one made from a close kept on this iPhone) and the counts.
struct ClosedBatch {
    let session: AttendanceSession
    let counts: CloseCounts
    let savedHere: Bool
}

extension TodayStore {
    public var hero: Hero? {
        let closedToday = closedBatches
        if let nextClass, nextClass.canMark {
            if let closed = closedToday.first(where: { $0.session.classID == nextClass.classroom.id }) {
                // Closed before its end: a batch not yet closed that is soon or running takes the hero.
                let closedIDs = Set(closedToday.compactMap(\.session.classID))
                let open = register.activeClasses.filter { !closedIDs.contains($0.id) }
                if let after = NextClass.find(in: open, now: clock, calendar: calendar), after.canMark {
                    return startHero(after)
                }
                return closedHero(closed)
            }
            return startHero(nextClass)
        }
        // After the batch, its close stays the hero until the next batch is soon.
        if let closed = closedToday
            .max(by: { ($0.session.closedAt ?? .distantPast) < ($1.session.closedAt ?? .distantPast) }),
            let hero = closedHero(closed) {
            return hero
        }
        return nextClass.map(upcomingHero)
    }

    /// Today's closes: those kept on this iPhone first (they are newer), then the server's.
    private var closedBatches: [ClosedBatch] {
        let kept: [ClosedBatch] = (queue?.pending.changes ?? []).compactMap { change in
            guard case let .close(close, _, _, _) = change.kind, close.date == today, close.classID != nil else {
                return nil
            }
            let session = AttendanceSession(
                id: change.id, classID: close.classID, date: close.date, savedAt: change.madeAt, marks: close.marks,
                closedAt: change.madeAt
            )
            let counts = CloseCounts(
                checks: close.checks.count, right: close.checks.count(where: \.correct), homework: close.homework.count
            )
            return ClosedBatch(session: session, counts: counts, savedHere: true)
        }
        let served = sessions.filter { session in
            session.date == today && session.closedAt != nil && session.classID != nil
                && !kept.contains { $0.session.classID == session.classID }
        }
        return kept + served.map {
            ClosedBatch(session: $0, counts: closeCounts[$0.id] ?? CloseCounts(), savedHere: false)
        }
    }

    private func startHero(_ next: NextClass) -> Hero {
        Hero(
            kind: .start, eyebrow: next.eyebrow, accent: true, title: next.classroom.name, titleMark: false,
            line: timeAndMembers(next.classroom), classID: next.classroom.id
        )
    }

    private func upcomingHero(_ next: NextClass) -> Hero {
        let classroom = next.classroom
        let members = Self.students(register.members(of: classroom.id).count)
        let time = classroom.timeRange
        return switch next {
        case .soon, .running, .laterToday:
            Hero(
                kind: .upcoming, eyebrow: next.eyebrow, accent: false, title: classroom.name, titleMark: false,
                line: timeAndMembers(classroom), classID: classroom.id
            )
        case .tomorrow:
            Hero(
                kind: .upcoming, eyebrow: next.eyebrow, accent: false, title: classroom.name, titleMark: false,
                line: [today.adding(days: 1, calendar: calendar).shortWeekdayText, time, members].compactMap(\.self)
                    .joined(separator: " · "),
                classID: classroom.id
            )
        case let .onDay(_, day):
            Hero(
                kind: .upcoming, eyebrow: next.eyebrow, accent: true,
                title: "Next: \(classroom.name) on \(day.weekday(in: calendar).name)", titleMark: false,
                line: [time, members, "its plan is made when you open the app on \(day.weekday(in: calendar).name)"]
                    .compactMap(\.self).joined(separator: " · "),
                classID: classroom.id
            )
        }
    }

    /// "Class 10 Maths · closed at 18:32", "5 of 6 came" with the tick, then the checks, homework and who was away.
    private func closedHero(_ closed: ClosedBatch) -> Hero? {
        let session = closed.session, counts = closed.counts
        guard let closedAt = session.closedAt, let classroom = register.classroom(session.classID) else { return nil }
        let when = closed.savedHere ? "saved on this iPhone"
            : "closed at \(QueuedChange.clock(closedAt, calendar: calendar))"
        var parts: [String] = []
        if counts.checks > 0 {
            parts.append("\(counts.right) of \(counts.checks) \(counts.checks == 1 ? "check" : "checks") right")
        }
        if counts.homework > 0 {
            parts.append("homework given to \(counts.homework)")
        }
        if let absent = absentLine(session) {
            parts.append(absent)
        }
        return Hero(
            kind: .closed, eyebrow: "\(classroom.name) · \(when)",
            accent: false, title: "\(session.presentCount) of \(session.marks.count) came", titleMark: true,
            line: parts.isEmpty ? timeAndMembers(classroom) : parts.joined(separator: " · "), classID: classroom.id
        )
    }

    /// "Nikhil absent", "Nikhil and Dev absent", "3 absent".
    private func absentLine(_ session: AttendanceSession) -> String? {
        let names = session.absentStudentIDs.compactMap { register.student($0)?.firstName }.sorted()
        return switch names.count {
        case 0: nil
        case 1: "\(names[0]) absent"
        case 2: "\(names[0]) and \(names[1]) absent"
        default: "\(names.count) absent"
        }
    }

    private func timeAndMembers(_ classroom: Classroom) -> String {
        [classroom.timeRange, Self.students(register.members(of: classroom.id).count)].compactMap(\.self)
            .joined(separator: " · ")
    }

    /// Today's closed sessions' checks and homework, read once the sessions are in.
    func readCloseCounts() async {
        let closed = sessions.filter { $0.date == today && $0.closedAt != nil }
        guard let record, !closed.isEmpty else { return }
        let students = Array(Set(closed.flatMap(\.marks.keys)))
        let since = calendar.startOfDay(for: clock)
        let centre = workspace.centre.id
        guard let checks = try? await record.checks(centre: centre, students: students, since: since),
              let homework = try? await record.homework(centre: centre, students: students, since: since)
        else { return }
        var counts: [UUID: CloseCounts] = [:]
        for check in checks where !check.isPlacement {
            guard let session = check.sessionID else { continue }
            counts[session, default: CloseCounts()].checks += 1
            counts[session, default: CloseCounts()].right += check.correct ? 1 : 0
        }
        for item in homework {
            counts[item.sessionID, default: CloseCounts()].homework += 1
        }
        closeCounts = counts
    }
}
