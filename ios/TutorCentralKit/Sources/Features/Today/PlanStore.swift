import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Where a plan line leads: its artefact's screen (AppShell's route).
public enum PlanOpen: Hashable, Sendable {
    case artefact(UUID)
    /// A not-on-track caption: the student's page.
    case student(UUID)
}

/// A group's card (P10-Today-Plan): the head with its marks, then a line per student.
public struct GroupCardModel: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let line: String
    public let marks: [ReadyMark]
    public let lines: [PlanLineModel]
}

/// A student's line in a group card.
public struct PlanLineModel: Identifiable, Hashable, Sendable {
    /// The student.
    public let id: UUID
    public let initials: String
    public let name: String
    public let status: String
    public let statusKind: TrackKind
    public let note: PlanLineNote?
    public let teach: String
    public let rest: [LineBit]
    public let items: [PlanItem]
    public let groupNo: Int
    /// "Since Fri 9 Oct · tell Ramesh after the class" (P10-Today-NotOnTrack): opens the student's page.
    public var caption: String?
}

/// The brief's row between the groups (the Phase 6 tool row).
public struct BriefRowModel: Hashable, Sendable, Identifiable {
    public var id: Int {
        afterGroup
    }

    public let title: String
    public let line: String
    public let artefactID: UUID?
    public let afterGroup: Int
}

/// One batch's plan on Today (P10-Today-Plan and its states), made by the server (Phase 18, D70): the plan row and the
/// day's plan job read together (plan/phase-18-plan.md decision 18). Being made (the planning card, or the plan with
/// its
/// marks on their way), made, failed with Try Again, none, a holiday, or the network away with no copy.
@MainActor @Observable public final class PlanStore {
    public enum State: Hashable, Sendable {
        case none
        case planning(PlanRecord?)
        case made(PlanRecord)
        case offline
        case failed(String)
        /// Every member is on holiday today (plan/phase-13-plan.md decision 17): no plan, no card.
        case holiday
    }

    public private(set) var state: State = .none
    public let classID: UUID
    public private(set) var groups: [GroupCardModel] = []
    public private(set) var briefRows: [BriefRowModel] = []
    /// Any line moved or skipped today.
    public private(set) var changedNote = false
    /// The system alert's words for a change refused or failed (U33).
    public var message: String?
    /// Whether the network is there (AppShell's connectivity); a test sets it.
    @ObservationIgnored public var online: () async -> Bool = { true }
    /// Whether the app is in front (AppShell's): the read while a job is live stops behind it.
    @ObservationIgnored public var inFront: () -> Bool = { true }
    /// The parents' log (AppShell's): who was told they are not on track, for the lines' captions.
    @ObservationIgnored public var messages: (any MessageLogRepository)?
    /// The members told since their status came; read with the plan.
    @ObservationIgnored var told: Set<UUID> = []
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let classes: any ClassesRepository
    let jobs: any JobsRepository
    let preview: PlanPreview
    let cache: PlanCache?
    let now: @Sendable () -> Date
    let calendar: Calendar
    /// The wait between reads while the job is live (ten seconds; a test passes none).
    let pause: @Sendable () async throws -> Void
    /// Each member's subjects (their chapters'), for the Change sheet's menus; read when it opens.
    @ObservationIgnored var subjects: [UUID: [String]] = [:]
    /// The exams' dates, by item, for an exam group's countdown (read with the plan).
    @ObservationIgnored var examDates: [UUID: Day] = [:]
    /// The day's plan job as last read.
    @ObservationIgnored var job: JobStatus?
    @ObservationIgnored var polling: Task<Void, Never>?
    @ObservationIgnored var followed = 0

    public init(
        classID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        classes: any ClassesRepository, jobs: any JobsRepository, preview: PlanPreview, cache: PlanCache?,
        now: @escaping @Sendable () -> Date, calendar: Calendar,
        pause: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(10)) }
    ) {
        self.classID = classID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.classes = classes
        self.jobs = jobs
        self.preview = preview
        self.cache = cache
        self.now = now
        self.calendar = calendar
        self.pause = pause
    }

    /// The words when the plan job failed: Try Again asks for another.
    static let jobFailed = "Couldn't make today's plan. Try again in a minute."
    /// The words when the plan could not be read (Phase 12's).
    static let readFailed = "Couldn't make today's plan. Check your connection and try again."

    public var briefRow: BriefRowModel? {
        briefRows.first
    }

    var today: Day {
        Day(now(), calendar: calendar)
    }

    var centre: UUID {
        workspace.centre.id
    }

    /// The plan on screen, made or being made.
    public var record: PlanRecord? {
        switch state {
        case let .planning(plan): plan
        case let .made(plan): plan
        default: nil
        }
    }

    var planning: Bool {
        if case .planning = state {
            return true
        }
        return false
    }

    /// The copy on this iPhone at once, then the plan and its job; no plan and no job asks the server for one, for a
    /// batch that meets today and has not been closed (decision 18). While the job is live the store reads again.
    public func load() async {
        let today = today
        guard let classroom = register.classroom(classID),
              classroom.meetingDays.contains(today.weekday(in: calendar)) else {
            show(.none)
            return
        }
        // A live job is being followed: a second open (a return to the app, a pull) reads nothing twice.
        guard polling == nil else { return }
        await readAround()
        if record == nil, let copy = cache?.load(classID: classID, date: today) {
            show(.made(copy.value))
        }
        guard await online() else {
            if record == nil {
                show(.offline)
            }
            return
        }
        await read(classroom, asking: true)
        if record != nil {
            await preview.keepBooks(of: register.members(of: classID))
        }
    }

    /// Try Again on the failed card: another plan job when the last one failed, else the read again.
    public func tryAgain() async {
        guard job?.state == .failed, record == nil else {
            await load()
            return
        }
        await ask(choices: nil)
    }

    /// Today's plan made again when an item changed for one of its members (a holiday, an exam): only while the batch
    /// meets today and its session is not closed; a batch wholly on holiday then has no plan.
    public func remake(for students: Set<UUID>) async {
        let today = today
        guard register.members(of: classID).contains(where: { students.contains($0.id) }),
              let classroom = register.classroom(classID),
              classroom.meetingDays.contains(today.weekday(in: calendar)) else { return }
        if let current = try? await plans.plan(centre: centre, classID: classID, date: today),
           current.sessionID != nil {
            return
        }
        guard await !preview.closed(classID: classID, date: today, centre: centre) else { return }
        await readAround()
        guard await !wholeBatchOnHoliday(classroom) else {
            show(.holiday)
            return
        }
        await ask(choices: PlanChoices(groups: nil, subjects: [:]))
    }

    /// A not-on-track message sent: the captions read again, the plan as it is.
    public func readCaptions() async {
        await readTold()
        if let record {
            groups = cards(record)
        }
    }

    /// One read of the plan and its job, and the state they make. `asking` lets a missing plan with no job ask for one
    /// (an open); the reads while a job is live only follow it.
    func read(_ classroom: Classroom, asking: Bool) async {
        async let planRead = plans.plan(centre: centre, classID: classID, date: today)
        async let jobRead = try? jobs.planJob(centre: centre, classID: classID, date: today)
        let made: PlanRecord?
        do {
            made = try await planRead
        } catch {
            _ = await jobRead
            if record == nil {
                show(TransportError.isOffline(error) ? .offline : .failed(Self.readFailed))
            }
            return
        }
        job = await jobRead
        let live = job?.isLive == true
        // A plan made before the live job was asked for is being replaced (Make the plan again, an item's change).
        if let made, !(live && made.madeAt < (job?.createdAt ?? .distantPast)) {
            await open(made, classroom: classroom, live: live)
            return
        }
        if live {
            show(.planning(nil))
            follow()
            return
        }
        switch job?.state {
        case .failed?:
            show(.failed(Self.jobFailed))
        case .done?:
            show(job?.reason == "holiday" ? .holiday : .none)
        default:
            // None asked for yet, or the last one cancelled: asked for now, unless closed or a holiday.
            guard asking else {
                show(.none)
                return
            }
            await askIfOpen(classroom)
        }
    }

    /// A plan read: shown, with its marks on their way while the job is live; none when the whole batch went on
    /// holiday after it was made and it is not closed (review Important 2).
    private func open(_ made: PlanRecord, classroom: Classroom, live: Bool) async {
        if made.sessionID == nil, await wholeBatchOnHoliday(classroom) {
            show(.holiday)
            return
        }
        show(live ? .planning(made) : .made(made))
        cache?.keep(made, at: now())
        if live {
            follow()
        }
    }

    private func askIfOpen(_ classroom: Classroom) async {
        guard await !preview.closed(classID: classID, date: today, centre: centre) else {
            show(.none)
            return
        }
        guard await !wholeBatchOnHoliday(classroom) else {
            show(.holiday)
            return
        }
        await ask(choices: nil)
    }

    /// A plan asked of the server (`request_plan`); choices, even none, replace the day's plan. The planning card shows
    /// until the plan is written, and the job is followed while it is live.
    func ask(choices: PlanChoices?) async {
        let asked: UUID
        do {
            asked = try await jobs.requestPlan(centre: centre, classID: classID, date: today, choices: choices)
        } catch {
            if record == nil {
                show(TransportError.isOffline(error) ? .offline : .failed(Self.jobFailed))
            } else {
                message = Self.changeFailed
            }
            return
        }
        job = JobStatus(id: asked, state: .queued, createdAt: now())
        show(.planning(nil))
        // Read at once: the live job a request answered may already have written its plan.
        if let classroom = register.classroom(classID) {
            await read(classroom, asking: false)
        }
        follow()
    }

    /// The exams' dates and who was told, read together: offline each takes a while to fail.
    private func readAround() async {
        async let exams: Void = readExamDates()
        async let told: Void = readTold()
        _ = await (exams, told)
    }

    private func readExamDates() async {
        guard let items = try? await preview.items(centre: centre) else { return }
        examDates = Dictionary(items.filter { $0.kind == .exam }.map { ($0.id, $0.date) }) { first, _ in first }
    }

    private func wholeBatchOnHoliday(_ classroom: Classroom) async -> Bool {
        await preview.wholeBatchOnHoliday(
            PlanBatch(classroom: classroom, members: register.members(of: classID), date: today, centre: centre)
        )
    }

    /// A line's artefact: the set, the checks (the student's own or the group's), the homework sheet, the brief.
    public func open(line: PlanItem) -> PlanOpen? {
        guard let plan = record else { return nil }
        let id: UUID? = switch line.kind {
        case .practise, .homework, .brief, .workedExample, .figure: line.artefactID
        case .check: line.studentID.flatMap { plan.checks(for: $0)?.id } ?? line.artefactID
        case .teach, .catchUp: nil
        }
        return id.map(PlanOpen.artefact)
    }

    /// The members' subjects for the Change sheet.
    public func readSubjects() async {
        subjects = await preview.subjects(of: register.members(of: classID))
    }

    func show(_ state: State) {
        self.state = state
        let plan = record
        groups = plan.map(cards) ?? []
        briefRows = plan.map(briefs) ?? []
        changedNote = plan?.items.contains { $0.movedFrom != nil || $0.skippedAt != nil } ?? false
    }
}
