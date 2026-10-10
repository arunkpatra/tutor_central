import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Today live (P4-Today-*): the heading, greeting and counts; the next class with its countdown; today's classes and
/// events; coming up; the tasks. A refresh that fails keeps the last numbers and says so (the stale pattern).
@MainActor @Observable public final class TodayStore {
    /// What the hero offers: Start class, Open the class once closed, nothing for a later batch.
    public enum HeroKind: Hashable, Sendable {
        case start
        case closed
        case upcoming
    }

    /// The batch hero (10.3): Start class while the next batch is soon or running; what happened once today's batch
    /// is closed, with Open the class; the next batch later, tomorrow or on a later day, with no button.
    public struct Hero: Hashable, Sendable {
        public let kind: HeroKind
        public let eyebrow: String
        public let accent: Bool
        public let title: String
        /// The closed hero's title carries the ok tick.
        public let titleMark: Bool
        public let line: String
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
    /// When the copy on screen was saved on this iPhone, until the network replaces it (D39).
    public private(set) var savedAt: Date?
    /// The last refresh failed for the network, not the server.
    public private(set) var offlineRead = false
    public private(set) var loading = false
    public private(set) var error: String?
    public private(set) var workspace: Workspace
    public private(set) var nextClass: NextClass?
    public let tasks: TasksStore
    private(set) var sessions: [AttendanceSession] = []
    private var events: [CalendarEvent] = []
    private(set) var clock: Date
    private let repository: any CountsRepository
    let register: any Register
    private let attendance: any AttendanceRepository
    private let eventsRepository: any EventsRepository
    private let now: @Sendable () -> Date
    public let calendar: Calendar
    private let cache: CachedRead<TodaySnapshot>?
    private var loaded = false
    let record: (any RecordRepository)?
    /// The centre's queue (AppShell's): a close kept on this iPhone reads closed on the hero before it is sent.
    public var queue: (any ChangeQueueing)?
    /// Today's closed sessions' checks and homework, by session, for the closed hero's line.
    var closeCounts: [UUID: CloseCounts] = [:]
    /// Builds a batch's plan store (AppShell's: the maker, the copy, the connectivity); nil shows no plan.
    @ObservationIgnored public var makePlanStore: ((UUID) -> PlanStore)?
    /// The plan of each batch meeting today, by batch.
    public private(set) var plans: [UUID: PlanStore] = [:]
    /// The batch whose plan card Today scrolls to (a student page's "Today", U35).
    public var focusBatch: UUID?

    public init(
        workspace: Workspace, counts: any CountsRepository, register: any Register,
        attendance: any AttendanceRepository, events: any EventsRepository, tasks: TasksStore,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india,
        cache: CachedRead<TodaySnapshot>? = nil, record: (any RecordRepository)? = nil
    ) {
        self.cache = cache
        self.record = record
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

    public var today: Day {
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

    /// The copy saved on this iPhone, at once, before the first read (D39).
    public func showCached() {
        guard !loaded, let cached = cache?.load() else { return }
        counts = cached.value.counts
        sessions = cached.value.sessions
        events = cached.value.events
        savedAt = cached.savedAt
        loaded = true
        tick(now())
    }

    public func load() async {
        if !loaded {
            loading = true
        }
        defer { loading = false }
        clock = now()
        let today = today
        async let monthSessions = try? attendance.sessions(centre: workspace.centre.id, month: today.period)
        // The register and the tasks show their saved copies at once, beside the counts' read (D39).
        let registerRead = Task { await register.loadIfNeeded() }
        let tasksRead = Task { await tasks.loadIfNeeded() }
        async let weekEvents = try? eventsRepository.events(
            centre: workspace.centre.id, from: today, to: today.adding(days: 7, calendar: calendar)
        )
        var fresh = false
        do {
            counts = try await repository.todayCounts(centre: workspace.centre.id, on: clock)
            error = nil
            offlineRead = false
            loaded = true
            fresh = true
        } catch {
            // Its screen went away mid-read: nothing failed; the next visit reads again.
            if TransportError.isCancelled(error) {
                return
            }
            offlineRead = TransportError.isOffline(error)
            // With a saved copy on screen the offline line says it; the error line is for nothing to show.
            self.error = savedAt == nil || !offlineRead ? "Couldn't refresh. Check your connection and try again." : nil
        }
        await registerRead.value
        await tasksRead.value
        if let read = await monthSessions {
            sessions = read
        }
        if let read = await weekEvents {
            events = read
        }
        await readCloseCounts()
        if fresh {
            savedAt = nil
            cache?.keep(TodaySnapshot(counts: counts, sessions: sessions, events: events), at: now())
        }
        tick(clock)
        // The counts are in; the plans fill their section as they are made.
        loading = false
        await loadPlans()
    }

    /// Today's batches in time order, each with its plan store: made (or read) one after another (plan decision 14).
    public var planBatches: [Classroom] {
        NextClass.classesToday(in: register.activeClasses, on: today, calendar: calendar)
    }

    func loadPlans() async {
        guard let makePlanStore else { return }
        for batch in planBatches {
            let store = plans[batch.id] ?? makePlanStore(batch.id)
            plans[batch.id] = store
            await store.load()
        }
    }

    static func students(_ count: Int) -> String {
        count == 1 ? "1 student" : "\(count) students"
    }
}

/// Where Today's buttons lead; AppShell supplies them (a feature never imports another).
public struct TodayActions {
    let openSettings: () -> Void
    let openTab: (AppTab) -> Void
    let openSchedule: () -> Void
    /// Start class and Open the class: the close of today's batch.
    let openClose: (UUID) -> Void
    let openClass: (UUID) -> Void
    let openEvent: (UUID) -> Void
    /// Today's Due tile: the Fees tab at Due.
    let openFeesDue: () -> Void
    /// The Create with AI row: the AI Assistant on Today's stack.
    let openAI: () -> Void
    /// The Start here card's Scan register: the scan on Today's stack.
    let openScanRegister: () -> Void
    /// A plan line's artefact: the sheet, the checks, the brief (the Artefacts feature, through AppShell's route).
    let openArtefact: (UUID) -> Void

    public init(
        openSettings: @escaping () -> Void,
        openTab: @escaping (AppTab) -> Void,
        openSchedule: @escaping () -> Void,
        openClose: @escaping (UUID) -> Void,
        openClass: @escaping (UUID) -> Void,
        openEvent: @escaping (UUID) -> Void,
        openFeesDue: @escaping () -> Void,
        openAI: @escaping () -> Void,
        openScanRegister: @escaping () -> Void,
        openArtefact: @escaping (UUID) -> Void = { _ in }
    ) {
        self.openSettings = openSettings
        self.openTab = openTab
        self.openSchedule = openSchedule
        self.openClose = openClose
        self.openClass = openClass
        self.openEvent = openEvent
        self.openFeesDue = openFeesDue
        self.openAI = openAI
        self.openScanRegister = openScanRegister
        self.openArtefact = openArtefact
    }
}

/// Today's copy on this iPhone (D39): the counts, the month's sessions, the week's events.
public struct TodaySnapshot: Codable, Sendable {
    public let counts: TodayCounts
    public let sessions: [AttendanceSession]
    public let events: [CalendarEvent]

    public init(counts: TodayCounts, sessions: [AttendanceSession], events: [CalendarEvent]) {
        self.counts = counts
        self.sessions = sessions
        self.events = events
    }
}
