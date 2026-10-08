import Foundation

/// The days a class meets in a month (the schedule's dots; Phase 5's attendance export).
public enum Occurrences {
    public static func days(of classroom: Classroom, in month: Period, calendar: Calendar) -> [Day] {
        guard !classroom.meetingDays.isEmpty,
              let range = calendar.range(of: .day, in: .month, for: month.start(in: calendar.timeZone))
        else { return [] }
        return range.compactMap { Day(year: month.year, month: month.month, day: $0) }
            .filter { classroom.meetingDays.contains($0.weekday(in: calendar)) }
    }
}
