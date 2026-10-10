import Domain
import Foundation

/// A closed session's counts for the hero's line: the checks, how many right, the homework given.
struct CloseCounts: Hashable, Sendable {
    var checks = 0
    var right = 0
    var homework = 0
}

extension TodayStore {
    public var hero: Hero? {
        let closedToday = sessions.filter { $0.date == today && $0.closedAt != nil && $0.classID != nil }
        if let nextClass, nextClass.canMark {
            if let closed = closedToday.first(where: { $0.classID == nextClass.classroom.id }) {
                return closedHero(closed)
            }
            return startHero(nextClass)
        }
        // After the batch, its close stays the hero until the next batch is soon.
        if let closed = closedToday.max(by: { ($0.closedAt ?? .distantPast) < ($1.closedAt ?? .distantPast) }),
           let hero = closedHero(closed) {
            return hero
        }
        return nextClass.map(upcomingHero)
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
    private func closedHero(_ session: AttendanceSession) -> Hero? {
        guard let closedAt = session.closedAt, let classroom = register.classroom(session.classID) else { return nil }
        let counts = closeCounts[session.id] ?? CloseCounts()
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
            kind: .closed, eyebrow: "\(classroom.name) · closed at \(QueuedChange.clock(closedAt, calendar: calendar))",
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
