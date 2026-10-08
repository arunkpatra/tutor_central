import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Today live (P4-Today-*): the heading, greeting and counts; the next class with its countdown; today's classes and
/// events; coming up; the tasks. A refresh that fails keeps the last numbers and says so (the stale pattern).
@MainActor @Observable public final class TodayStore {
    /// The hero card: the next class with the time until it starts and Mark attendance, or the next class day.
    public struct Hero: Hashable, Sendable {
        public let eyebrow: String
        public let accent: Bool
        public let title: String
        public let line: String
        public let canMark: Bool
        public let classID: UUID
    }

    /// A row of the Today section: a class (time over end, "5 of 6 present" once marked) or an event.
    public struct TodayRow: Hashable, Sendable, Identifiable {
        /// The class's id or the event's.
        public let id: UUID
        public let classroom: Classroom?
        public let event: CalendarEvent?
        public let start: String
        public let end: String?
        public let title: String
        public let line: String?
        public let lineTone: StatusTone?
        public let marked: Bool
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

    public private(set) var counts: TodayCounts = .zero
    public private(set) var loading = false
    public private(set) var error: String?
    public private(set) var workspace: Workspace
    public private(set) var nextClass: NextClass?
    public let tasks: TasksStore
    private var sessions: [AttendanceSession] = []
    private var events: [CalendarEvent] = []
    private var clock: Date
    private let repository: any CountsRepository
    private let register: any Register
    private let attendance: any AttendanceRepository
    private let eventsRepository: any EventsRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var loaded = false

    public init(
        workspace: Workspace, counts: any CountsRepository, register: any Register,
        attendance: any AttendanceRepository, events: any EventsRepository, tasks: TasksStore,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        repository = counts
        self.register = register
        self.attendance = attendance
        eventsRepository = events
        self.tasks = tasks
        self.now = now
        self.calendar = calendar
        clock = now()
    }

    public var heading: String {
        DayHeading.long(clock, calendar: calendar)
    }

    public var greeting: String {
        Greeting.text(at: clock, firstName: workspace.profile.firstName, calendar: calendar)
    }

    public var initials: String {
        workspace.profile.initials
    }

    private var today: Day {
        Day(clock, calendar: calendar)
    }

    /// The empty register's first step (Phase 2's card): no students and no classes, and a read has said so.
    public var showsStartHere: Bool {
        register.showsEmptyRegister && register.activeClasses.isEmpty
    }

    /// True once the register has classes: an empty Today section then says "Nothing today", not "No classes yet".
    public var hasClasses: Bool {
        !register.activeClasses.isEmpty
    }

    public var hero: Hero? {
        guard let nextClass else { return nil }
        let classroom = nextClass.classroom
        let members = Self.students(register.members(of: classroom.id).count)
        let time = classroom.timeRange
        switch nextClass {
        case .soon, .running:
            return Hero(
                eyebrow: nextClass.eyebrow, accent: true, title: classroom.name,
                line: [time, members].compactMap(\.self).joined(separator: " · "), canMark: true,
                classID: classroom.id
            )
        case .laterToday:
            return Hero(
                eyebrow: nextClass.eyebrow, accent: false, title: classroom.name,
                line: [time, members].compactMap(\.self).joined(separator: " · "), canMark: false,
                classID: classroom.id
            )
        case .tomorrow:
            let day = today.adding(days: 1, calendar: calendar).shortWeekdayText
            return Hero(
                eyebrow: nextClass.eyebrow, accent: false, title: classroom.name,
                line: [day, time, members].compactMap(\.self).joined(separator: " · "), canMark: false,
                classID: classroom.id
            )
        case let .onDay(_, day):
            return Hero(
                eyebrow: nextClass.eyebrow, accent: false, title: "Next class on \(day.weekday(in: calendar).name)",
                line: [classroom.name, day.shortWeekdayText, time].compactMap(\.self).joined(separator: " · "),
                canMark: false, classID: classroom.id
            )
        }
    }

    public var todayRows: [TodayRow] {
        let classes = NextClass.classesToday(in: register.activeClasses, on: today, calendar: calendar)
            .map { classroom in
                let session = sessions.first { $0.date == today && $0.classID == classroom.id }
                return TodayRow(
                    id: classroom.id, classroom: classroom, event: nil,
                    start: classroom.startTime?.text ?? "Today", end: classroom.endTime?.text, title: classroom.name,
                    line: session.map { "\($0.presentCount) of \($0.marks.count) present" }
                        ?? "\(classroom.daysSummary) · \(Self.students(register.members(of: classroom.id).count))",
                    lineTone: session == nil ? nil : .ok,
                    marked: session != nil
                )
            }
        let events = CalendarEvent.on(today, in: events).map { event in
            TodayRow(
                id: event.id, classroom: nil, event: event, start: event.startTime?.text ?? "All day",
                end: event.endTime?.text,
                title: event.title, line: event.line, lineTone: nil, marked: false
            )
        }
        return classes + events
    }

    /// The next seven days' events (design-tokens.md, "Numbers in code"), at most five.
    public var comingUp: [ComingLine] {
        CalendarEvent.comingUp(events, after: today, calendar: calendar).prefix(Self.comingUpLimit).map {
            ComingLine(event: $0, day: "\($0.date.weekday(in: calendar).short) \($0.date.day)", line: $0.comingUpLine)
        }
    }

    public static let comingUpLimit = 5

    /// Settings edits the name; the greeting and initials follow.
    public func workspaceChanged(_ workspace: Workspace) {
        self.workspace = workspace
    }

    /// The minute clock: the countdown and the next class follow it.
    public func tick(_ date: Date) {
        clock = date
        nextClass = NextClass.find(in: register.activeClasses, now: date, calendar: calendar)
    }

    public func load() async {
        if !loaded {
            loading = true
        }
        defer { loading = false }
        clock = now()
        let today = today
        async let monthSessions = try? attendance.sessions(centre: workspace.centre.id, month: today.period)
        async let weekEvents = try? eventsRepository.events(
            centre: workspace.centre.id, from: today, to: today.adding(days: 7, calendar: calendar)
        )
        do {
            counts = try await repository.todayCounts(centre: workspace.centre.id, on: clock)
            error = nil
            loaded = true
        } catch {
            self.error = "Couldn't refresh. Check your connection and try again."
        }
        await register.loadIfNeeded()
        await tasks.loadIfNeeded()
        if let read = await monthSessions {
            sessions = read
        }
        if let read = await weekEvents {
            events = read
        }
        tick(clock)
    }

    private static func students(_ count: Int) -> String {
        count == 1 ? "1 student" : "\(count) students"
    }
}

/// Where Today's buttons lead; AppShell supplies them (a feature never imports another).
public struct TodayActions {
    let openSettings: () -> Void
    let openTab: (AppTab) -> Void
    let openSchedule: () -> Void
    let openMarkAttendance: (UUID) -> Void
    let openClass: (UUID) -> Void
    let openEvent: (UUID) -> Void
    /// Today's Due tile: the Fees tab at Due.
    let openFeesDue: () -> Void
    /// The Create with AI row: the AI Assistant on Today's stack.
    let openAI: () -> Void

    public init(
        openSettings: @escaping () -> Void,
        openTab: @escaping (AppTab) -> Void,
        openSchedule: @escaping () -> Void,
        openMarkAttendance: @escaping (UUID) -> Void,
        openClass: @escaping (UUID) -> Void,
        openEvent: @escaping (UUID) -> Void,
        openFeesDue: @escaping () -> Void,
        openAI: @escaping () -> Void
    ) {
        self.openSettings = openSettings
        self.openTab = openTab
        self.openSchedule = openSchedule
        self.openMarkAttendance = openMarkAttendance
        self.openClass = openClass
        self.openEvent = openEvent
        self.openFeesDue = openFeesDue
        self.openAI = openAI
    }
}
