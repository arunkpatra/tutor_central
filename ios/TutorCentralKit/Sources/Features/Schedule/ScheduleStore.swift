import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// The schedule (P4-Schedule-Month, -Day): a month with its marked days, the chosen day's classes and events, and
/// coming up when today is chosen; events added, edited and deleted. Made per screen.
@MainActor @Observable public final class ScheduleStore {
    /// A class meeting on the chosen day: its time, and "5 of 6 present" once marked, else its days and size.
    public struct ClassLine: Hashable, Sendable, Identifiable {
        public let classroom: Classroom
        public let start: String
        public let end: String?
        public let line: String
        public let lineTone: StatusTone?
        public let marked: Bool
        public var id: UUID {
            classroom.id
        }
    }

    /// An event on the chosen day: its start ("All day" without one) over its end, the note or the time.
    public struct EventLine: Hashable, Sendable, Identifiable {
        public let event: CalendarEvent
        public let start: String
        public let end: String?
        public let line: String?
        public var id: UUID {
            event.id
        }
    }

    /// An event of the next seven days: "Sat 10" and "11:00–12:00 · Class 10 parents".
    public struct ComingLine: Hashable, Sendable, Identifiable {
        public let event: CalendarEvent
        public let day: String
        public let line: String?
        public var id: UUID {
            event.id
        }
    }

    public private(set) var month: Period
    public private(set) var selected: Day
    public private(set) var events: [CalendarEvent] = []
    public private(set) var sessions: [AttendanceSession] = []
    public private(set) var loading = false
    public private(set) var error: String?
    public var message: String?
    public private(set) var canRetry = false
    public private(set) var lastSavedAt: Date?
    private var lastFailed: (@MainActor () async -> Void)?
    private let workspace: Workspace
    private let register: any Register
    private let eventsRepository: any EventsRepository
    private let attendance: any AttendanceRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        workspace: Workspace, register: any Register, events: any EventsRepository,
        attendance: any AttendanceRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        eventsRepository = events
        self.attendance = attendance
        self.now = now
        self.calendar = calendar
        month = Period.containing(now(), in: calendar.timeZone)
        selected = Day(now(), calendar: calendar)
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    public var monthTitle: String {
        month.title
    }

    /// The days with a class meeting or an event, for the calendar's dots.
    public var markedDays: Set<Day> {
        let classDays = register.activeClasses.flatMap { Occurrences.days(of: $0, in: month, calendar: calendar) }
        return Set(classDays).union(events.map(\.date))
    }

    /// "Today, 7 October" or "Saturday 10 October".
    public var dayTitle: String {
        selected == today ? "Today, \(selected.longText)" : selected.weekdayLongText
    }

    public var classRows: [ClassLine] {
        NextClass.classesToday(in: register.activeClasses, on: selected, calendar: calendar).map { classroom in
            let session = sessions.first { $0.date == selected && $0.classID == classroom.id }
            let members = register.members(of: classroom.id).count
            return ClassLine(
                classroom: classroom,
                start: classroom.startTime?.text ?? "No time",
                end: classroom.endTime?.text,
                line: session.map { "\($0.presentCount) of \($0.marks.count) present" }
                    ?? "\(classroom.daysSummary) · \(members == 1 ? "1 student" : "\(members) students")",
                lineTone: session == nil ? nil : .ok,
                marked: session != nil
            )
        }
    }

    public var eventRows: [EventLine] {
        CalendarEvent.on(selected, in: events).map {
            EventLine(event: $0, start: $0.startTime?.text ?? "All day", end: $0.endTime?.text, line: $0.line)
        }
    }

    /// "No classes meet on Saturdays." under a day without a class.
    public var noClassLine: String? {
        guard classRows.isEmpty else { return nil }
        return "No classes meet on \(selected.weekday(in: calendar).name)s."
    }

    /// Only with today chosen. The schedule looks two weeks ahead (P4-Schedule-Month draws Sat 17 on Wed 7), Today one.
    public static let comingUpDays = 14

    public var comingUp: [ComingLine] {
        guard selected == today else { return [] }
        return CalendarEvent.comingUp(events, after: today, days: Self.comingUpDays, calendar: calendar).map {
            ComingLine(event: $0, day: "\($0.date.weekday(in: calendar).short) \($0.date.day)", line: $0.comingUpLine)
        }
    }

    public func load() async {
        await register.loadIfNeeded()
        loading = true
        defer { loading = false }
        guard let first = Day(iso: month.isoDay), let last = Day(iso: month.next.previousDayISO) else { return }
        do {
            // Coming up runs past the month's end: read its two weeks beyond it.
            let to = last.adding(days: Self.comingUpDays, calendar: calendar)
            async let read = eventsRepository.events(centre: workspace.centre.id, from: first, to: to)
            async let marked = attendance.sessions(centre: workspace.centre.id, month: month)
            (events, sessions) = try await (read, marked)
            error = nil
        } catch {
            self.error = "Couldn't load the schedule. Check your connection and try again."
        }
    }

    public func select(_ day: Day) async {
        selected = day
        if day.period != month {
            month = day.period
            await load()
        }
    }

    public func previousMonth() async {
        await move(to: month.previous)
    }

    public func nextMonth() async {
        await move(to: month.next)
    }

    /// Waits for the server: the sheet shows its loading state.
    public func add(_ draft: EventDraft) async -> CalendarEvent? {
        do {
            let made = try await eventsRepository.create(draft, centre: workspace.centre.id)
            events.append(made)
            saved()
            return made
        } catch {
            failed("Couldn't save the event. Check your connection and try again.") { [weak self] in
                _ = await self?.add(draft)
            }
            return nil
        }
    }

    /// Shown at once, rolled back if the server refuses.
    public func update(_ id: UUID, with draft: EventDraft) async -> Bool {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return false }
        let before = events[index]
        events[index] = CalendarEvent(
            id: id, title: draft.trimmedTitle, date: draft.date, startTime: draft.startTime, endTime: draft.endTime,
            note: draft.trimmedNote
        )
        do {
            let changed = try await eventsRepository.update(id: id, with: draft)
            if let now = events.firstIndex(where: { $0.id == id }) {
                events[now] = changed
            }
            saved()
            return true
        } catch {
            if let now = events.firstIndex(where: { $0.id == id }) {
                events[now] = before
            }
            failed("Couldn't save the event. Check your connection and try again.") { [weak self] in
                _ = await self?.update(id, with: draft)
            }
            return false
        }
    }

    /// Waits for the server: an event shown as gone before it is would mislead.
    public func delete(_ id: UUID) async -> Bool {
        do {
            try await eventsRepository.delete(id: id)
            events.removeAll { $0.id == id }
            saved()
            return true
        } catch {
            failed("Couldn't delete the event. Check your connection and try again.") { [weak self] in
                _ = await self?.delete(id)
            }
            return false
        }
    }

    public func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }

    private func move(to period: Period) async {
        month = period
        selected = period == today.period ? today : Day(iso: period.isoDay) ?? today
        await load()
    }

    private func saved() {
        lastSavedAt = now()
        lastFailed = nil
        canRetry = false
    }

    private func failed(_ text: String, retry: @escaping @MainActor () async -> Void) {
        message = text
        canRetry = true
        lastFailed = retry
    }
}
