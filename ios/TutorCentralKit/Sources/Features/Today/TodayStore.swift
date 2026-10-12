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
    /// What the schools sent and the message log (Phase 13): To parents after the close.
    @ObservationIgnored public var schoolItems: (any SchoolItemsRepository)?
    @ObservationIgnored public var messages: (any MessageLogRepository)?
    /// The messages that go now after today's close (P10-Today-AfterClose).
    public internal(set) var toParents: [ParentRowModel] = []
    /// The note day (Phase 14): AppShell's store, read with Today; nil shows none.
    @ObservationIgnored public var noteDay: NoteDayStore?
    /// After a close: the Weekly notes row (P10-Today-AfterClose), the closed batch's note weekday and the words.
    public internal(set) var notesWaitingTitle = ""
    public internal(set) var notesWaiting: String?

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

    /// The copy at once, then the counts, the month's sessions and the week's events read together beside the
    /// register, the tasks and the plans (D76); a failed read keeps what is shown.
    public func load() async {
        if !loaded {
            loading = true
        }
        defer { loading = false }
        clock = now()
        let today = today
        // The register and the tasks show their saved copies at once, beside the counts' read (D39).
        let registerRead = Task { await register.loadIfNeeded() }
        let tasksRead = Task { await tasks.loadIfNeeded() }
        // The plans start once the register is in, beside the counts: each shows its copy at once offline, where
        // the counts' read takes its timeout to fail.
        async let plansRead: Void = startPlans(after: registerRead)
        // The note day too: its rows come from the register at once, its read beside the counts.
        async let noteDayRead: Void = startNoteDay(after: registerRead)
        let (repository, attendance, events, centre, at, calendar) = (
            repository, attendance, eventsRepository, workspace.centre.id, clock, calendar
        )
        let outcome = await CopyFirst(cache: cache, now: now).load(showingCopy: !loaded) { snapshot, savedAt in
            show(snapshot, savedAt: savedAt)
        } read: {
            async let monthSessions = attendance.sessions(centre: centre, month: today.period)
            async let weekEvents = events.events(
                centre: centre, from: today, to: today.adding(days: 7, calendar: calendar)
            )
            let counts = try await repository.todayCounts(centre: centre, on: at)
            return try await TodaySnapshot(counts: counts, sessions: monthSessions, events: weekEvents)
        }
        if let failure = outcome.failure {
            // Its screen went away mid-read: nothing failed; the next visit reads again.
            if TransportError.isCancelled(failure) {
                return
            }
            offlineRead = TransportError.isOffline(failure)
            // With a saved copy on screen the offline line says it; the error line is for nothing to show.
            error = savedAt == nil || !offlineRead ? "Couldn't refresh. Check your connection and try again." : nil
        } else {
            error = nil
            offlineRead = false
        }
        await registerRead.value
        await tasksRead.value
        await readCloseCounts()
        await loadParents()
        await noteDayRead
        tick(clock)
        // The counts are in; the plans fill their section as they are made.
        loading = false
        await plansRead
    }

    private func show(_ snapshot: TodaySnapshot, savedAt: Date) {
        counts = snapshot.counts
        sessions = snapshot.sessions
        events = snapshot.events
        self.savedAt = savedAt
        loaded = true
        tick(clock)
    }

    private func startPlans(after registerRead: Task<Void, Never>) async {
        await registerRead.value
        await loadPlans()
    }

    private func startNoteDay(after registerRead: Task<Void, Never>) async {
        await registerRead.value
        await noteDay?.load()
    }

    /// Today's batches in time order, each with its plan store: made (or read) one after another (plan decision 14).
    public var planBatches: [Classroom] {
        NextClass.classesToday(in: register.activeClasses, on: today, calendar: calendar)
    }

    func loadPlans() async {
        guard let makePlanStore else { return }
        let stores = planBatches.map { batch in
            let store = plans[batch.id] ?? makePlanStore(batch.id)
            plans[batch.id] = store
            return store
        }
        // Every batch's copy first: the batches read one after another, and offline each read takes its timeout.
        stores.forEach { $0.showCopy() }
        for store in stores {
            await store.load()
        }
    }

    /// An item added, changed or deleted reached these students (decision 16): each of today's plans with one of them
    /// is made again, and To parents reads the items again.
    public func remakePlans(for students: Set<UUID>) async {
        for store in plans.values {
            await store.remake(for: students)
        }
        await loadParents()
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
    /// To parents' Send: Test tomorrow's sheet (School's) or the absence alert, through AppShell.
    let sendToParent: (ParentRowModel) -> Void
    /// A plan line's not-on-track caption: the student's page (Phase 14).
    let openStudent: (UUID) -> Void

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
        openArtefact: @escaping (UUID) -> Void = { _ in },
        sendToParent: @escaping (ParentRowModel) -> Void = { _ in },
        openStudent: @escaping (UUID) -> Void = { _ in }
    ) {
        self.sendToParent = sendToParent
        self.openStudent = openStudent
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
