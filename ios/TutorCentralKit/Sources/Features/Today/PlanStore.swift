import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// Where a plan line leads: its artefact's screen (AppShell's route).
public enum PlanOpen: Hashable, Sendable {
    case artefact(UUID)
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

/// One batch's plan on Today (P10-Today-Plan and its states): nothing yet, being made (the lines fill in as they come),
/// made, or none because the network is away and no copy exists (plan decision 14).
@MainActor @Observable public final class PlanStore {
    public enum State: Hashable, Sendable {
        case none
        case planning(PlanRecord?)
        case made(PlanRecord)
        case offline
        case failed(String)
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
    @ObservationIgnored public var online: () -> Bool = { true }
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let classes: any ClassesRepository
    let maker: PlanMaker
    let cache: PlanCache?
    let now: @Sendable () -> Date
    let calendar: Calendar
    /// Each member's subjects (their chapters'), for the Change sheet's menus; read when it opens.
    @ObservationIgnored var subjects: [UUID: [String]] = [:]
    @ObservationIgnored var generation = 0
    @ObservationIgnored var run: Task<Void, Never>?

    public init(
        classID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository,
        classes: any ClassesRepository, maker: PlanMaker, cache: PlanCache?, now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
        self.classID = classID
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.classes = classes
        self.maker = maker
        self.cache = cache
        self.now = now
        self.calendar = calendar
    }

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

    /// The copy on this iPhone at once, then the plan already made, completed when material is missing; else made now,
    /// for a batch that meets today and has not been closed (plan decision 14).
    public func load() async {
        let today = today
        guard let classroom = register.classroom(classID),
              classroom.meetingDays.contains(today.weekday(in: calendar)) else {
            show(.none)
            return
        }
        if record == nil, let copy = cache?.load(classID: classID, date: today) {
            show(.made(copy.value))
        }
        guard online() else {
            if record == nil {
                show(.offline)
            }
            return
        }
        let made: PlanRecord?
        do {
            made = try await plans.plan(centre: centre, classID: classID, date: today)
        } catch {
            if record == nil {
                show(TransportError.isOffline(error) ? .offline : .failed(PlanMaker.readFailed))
            }
            return
        }
        if let made {
            show(.made(made))
            cache?.keep(made, at: now())
            await complete(made)
            return
        }
        guard await !maker.closed(classID: classID, date: today, centre: centre) else {
            show(.none)
            return
        }
        await make(choices: nil)
    }

    /// Makes the day's plan (again): the run before it is cancelled and its late answers dropped.
    func make(choices: PlanChoices?) async {
        guard let classroom = register.classroom(classID) else { return }
        generation += 1
        let mine = generation
        run?.cancel()
        show(.planning(nil))
        let batch = PlanBatch(
            classroom: classroom, members: register.members(of: classID), date: today, centre: centre
        )
        let task = Task { [maker] in
            await maker.make(batch, choices: choices) { [weak self] progress in
                await self?.apply(progress, mine)
            }
        }
        run = task
        await task.value
    }

    /// The material the plan is still missing (a refresh that iOS stopped part-way), made into the plan as it is.
    private func complete(_ plan: PlanRecord) async {
        generation += 1
        let mine = generation
        let members = register.members(of: classID)
        let centre = centre
        let task = Task { [maker] in
            await maker.complete(plan, members: members, centre: centre) { [weak self] progress in
                await self?.apply(progress, mine)
            }
        }
        run = task
        await task.value
    }

    /// A run's news on screen. A kept artefact is linked into the plan as shown (a student moved meanwhile follows the
    /// new group, as `keep_artefact` linked them), so a change made while the material lands is kept.
    private func apply(_ progress: PlanMaker.Progress, _ mine: Int) {
        guard mine == generation else { return }
        switch progress {
        case let .written(plan):
            show(.planning(plan))
        case let .kept(artefact, plan):
            let merged = record.map { $0.id == plan.id ? $0.merging(artefact, from: plan) : plan } ?? plan
            show(.planning(merged))
            cache?.keep(merged, at: now())
        case let .finished(plan):
            show(.made(record.map { $0.id == plan.id ? $0 : plan } ?? plan))
        case let .failed(words):
            if record == nil {
                show(.failed(words))
            } else if let plan = record {
                show(.made(plan))
            }
        }
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
        subjects = await maker.subjects(of: register.members(of: classID))
    }

    func show(_ state: State) {
        self.state = state
        let plan = record
        groups = plan.map(cards) ?? []
        briefRows = plan.map(briefs) ?? []
        changedNote = plan?.items.contains { $0.movedFrom != nil || $0.skippedAt != nil } ?? false
    }
}
