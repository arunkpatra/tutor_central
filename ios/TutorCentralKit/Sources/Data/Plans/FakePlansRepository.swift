import Domain
import Foundation

/// The in-memory plans for tests, previews and `bun shots`: the same rules as the functions (a second make replaces the
/// day's plan and unlinks its artefacts; a keep links the group's or one student's items), a scripted error, a delay,
/// every write recorded.
@MainActor public final class FakePlansRepository: PlansRepository {
    public private(set) var plans: [PlanRecord]
    /// Every artefact kept, linked or not (a regenerated one stays, as in the database).
    public private(set) var artefacts: [Artefact] = []
    public private(set) var made: [PlanDraft] = []
    public private(set) var kept: [NewArtefact] = []
    public private(set) var skipped: [UUID] = []
    public var nextError: (any Error)?
    /// Every call waits this long first: lets a store's writes overlap, as a real network can.
    public var delay: Duration?
    /// A make waits this long more (the plan still being written: P10-Today-Planning).
    public var makeDelay: Duration?
    /// The time a make or keep is stamped with.
    public var now: Date

    public init(plans: [PlanRecord] = [], artefacts: [Artefact] = [], now: Date = FakeCountsRepository.fixedNow) {
        self.plans = plans
        self.artefacts = artefacts
        self.now = now
    }

    public func plan(centre _: UUID, classID: UUID, date: Day) async throws -> PlanRecord? {
        try await begin()
        guard let plan = plans.first(where: { $0.classID == classID && $0.date == date }) else { return nil }
        return withArtefacts(plan)
    }

    public func make(_ draft: PlanDraft, centre _: UUID) async throws -> PlanRecord {
        try await begin()
        if let makeDelay {
            try? await Task.sleep(for: makeDelay)
        }
        made.append(draft)
        let existing = plans.firstIndex { $0.classID == draft.classID && $0.date == draft.date }
        let items = draft.lines.map { line in
            PlanItem(
                id: UUID(), studentID: line.studentID, groupNo: line.groupNo, kind: line.kind, skillID: line.skillID,
                words: line.words, artefactID: nil, doneAt: nil, skippedAt: nil, movedFrom: nil
            )
        }
        let record = PlanRecord(
            id: existing.map { plans[$0].id } ?? UUID(), classID: draft.classID, date: draft.date, madeAt: now,
            groups: draft.groups, items: items, artefacts: [], sessionID: nil
        )
        if let existing {
            plans[existing] = record
        } else {
            plans.append(record)
        }
        return record
    }

    public func keep(_ artefact: NewArtefact, to link: ArtefactLink, centre _: UUID) async throws -> Artefact {
        try await begin()
        kept.append(artefact)
        let made = Artefact(
            id: UUID(), kind: artefact.kind, source: artefact.source, title: artefact.title, content: artefact.content,
            photoPath: artefact.photoPath, studentID: link.student, planID: link.plan,
            regeneratedFrom: artefact.regeneratedFrom,
            madeAt: now
        )
        artefacts.append(made)
        if let index = plans.firstIndex(where: { $0.id == link.plan }) {
            for item in plans[index].items.indices where Self.links(plans[index].items[item], link) {
                plans[index].items[item].artefactID = made.id
            }
        }
        return made
    }

    public func artefact(id: UUID, centre _: UUID) async throws -> Artefact? {
        try await begin()
        return artefacts.first { $0.id == id }
    }

    public func briefChapters(centre _: UUID) async throws -> Set<String> {
        try await begin()
        return Set(artefacts.filter { $0.kind == .brief }.map { SupabasePlansRepository.chapter(ofBrief: $0.title) })
    }

    public func skip(item: UUID, centre _: UUID) async throws {
        try await begin()
        skipped.append(item)
        update { $0.id == item } with: { $0.skippedAt = now }
    }

    public func move(items: [UUID], to group: Int, from: Int, centre _: UUID) async throws {
        try await begin()
        update { items.contains($0.id) } with: { item in
            item.groupNo = group
            item.movedFrom = from
        }
    }

    public func leaveOut(student: UUID, plan: UUID, centre _: UUID) async throws {
        try await begin()
        guard let index = plans.firstIndex(where: { $0.id == plan }) else { return }
        for item in plans[index].items.indices where plans[index].items[item].studentID == student {
            plans[index].items[item].skippedAt = now
        }
    }

    public func link(items: [UUID], to artefact: UUID?, centre _: UUID) async throws {
        try await begin()
        update { items.contains($0.id) } with: { $0.artefactID = artefact }
    }

    /// Marks the close's done lines, as `close_session`'s `p_done` does.
    public func markDone(_ items: Set<UUID>, session: UUID?) {
        update { items.contains($0.id) && $0.doneAt == nil } with: { $0.doneAt = now }
        if let session, let index = plans.firstIndex(where: { $0.items.contains { items.contains($0.id) } }) {
            plans[index].sessionID = session
        }
    }

    private static func links(_ item: PlanItem, _ link: ArtefactLink) -> Bool {
        guard item.kind == link.itemKind else { return false }
        return link.student.map { item.studentID == $0 } ?? (item.groupNo == link.group)
    }

    private func withArtefacts(_ plan: PlanRecord) -> PlanRecord {
        var record = plan
        record.artefacts = artefacts.filter { $0.planID == plan.id }
        return record.keepingLinkedArtefacts()
    }

    private func update(_ matching: (PlanItem) -> Bool, with change: (inout PlanItem) -> Void) {
        for plan in plans.indices {
            for item in plans[plan].items.indices where matching(plans[plan].items[item]) {
                change(&plans[plan].items[item])
            }
        }
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
