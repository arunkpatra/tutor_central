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
    /// Tests: `keep` waits this long first, and a cancelled task stops there (as a cancelled request does).
    public var keepDelay: Duration?
    /// Tests: `notes` answers this long after it is asked (a connection that hangs).
    public var notesDelay: Duration?
    /// The notes the check set aside, by student: the refused draft (`setAsideNotes`), unless a note is kept since.
    public var setAside: [UUID: UUID] = [:]
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

    public func plan(id: UUID, centre _: UUID) async throws -> PlanRecord? {
        try await begin()
        return plans.first { $0.id == id }.map(withArtefacts)
    }

    /// The draft written as the server's plan job writes it (`make_plan`; the fixtures' and the tests' plan job): a
    /// second call replaces the day's plan.
    public func make(_ draft: PlanDraft, centre _: UUID) async throws -> PlanRecord {
        try await begin()
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
        if let keepDelay {
            try await Task.sleep(for: keepDelay)
        }
        try await begin()
        kept.append(artefact)
        let made = Artefact(
            id: UUID(), kind: artefact.kind, source: artefact.source, title: artefact.title, content: artefact.content,
            photoPath: artefact.photoPath, studentID: link.student, planID: link.plan,
            regeneratedFrom: artefact.regeneratedFrom,
            madeAt: now, generationID: artefact.generationID, schoolItemID: link.schoolItem,
            madeFrom: artefact.madeFor == nil ? nil : "make", madeFor: artefact.madeFor
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

    public func mock(for item: UUID, centre: UUID) async throws -> Artefact? {
        try await artefacts(for: item, centre: centre).first { $0.kind == .mock }
    }

    public func gapReport(for item: UUID, student: UUID, centre: UUID) async throws -> Artefact? {
        try await artefacts(for: item, centre: centre).first { $0.kind == .gapReport && $0.studentID == student }
    }

    public func artefacts(for item: UUID, centre _: UUID) async throws -> [Artefact] {
        try await begin()
        return artefacts.filter { $0.schoolItemID == item }.reversed()
    }

    public func notes(centre _: UUID, students: [UUID], since: Date) async throws -> [Artefact] {
        if let notesDelay {
            try await Task.sleep(for: notesDelay)
        }
        try await begin()
        return artefacts.filter { artefact in
            [.note, .canDo].contains(artefact.kind) && artefact.madeAt >= since
                && artefact.studentID.map(students.contains) == true
        }.reversed()
    }

    public func setAsideNotes(centre _: UUID, students: [UUID], since: Date) async throws -> [UUID: UUID] {
        try await begin()
        let haveNotes = Set(artefacts.filter { [.note, .canDo].contains($0.kind) && $0.madeAt >= since }
            .compactMap(\.studentID))
        return setAside.filter { students.contains($0.key) && !haveNotes.contains($0.key) }
    }

    public func made(centre _: UUID) async throws -> [Artefact] {
        try await begin()
        return Array(artefacts.filter(\.isMade).sorted { $0.madeAt > $1.madeAt }.prefix(50)).hidingRegenerated()
    }

    public func setContent(_ content: ArtefactContent, artefact: UUID, centre _: UUID) async throws {
        try await begin()
        guard let index = artefacts.firstIndex(where: { $0.id == artefact }) else { return }
        let old = artefacts[index]
        artefacts[index] = Artefact(
            id: old.id, kind: old.kind, source: old.source, title: old.title, content: content,
            photoPath: old.photoPath,
            studentID: old.studentID, planID: old.planID, regeneratedFrom: old.regeneratedFrom, madeAt: old.madeAt,
            generationID: old.generationID, schoolItemID: old.schoolItemID
        )
    }

    /// The chapters a brief was made for: the fixtures' plan job adds a brief line for the others.
    public func briefChapters(centre _: UUID) async throws -> Set<String> {
        try await begin()
        let prefix = PlanRules.briefPrefix
        return Set(artefacts.filter { $0.kind == .brief }.map { brief in
            brief.title.hasPrefix(prefix) ? String(brief.title.dropFirst(prefix.count)) : brief.title
        })
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
        let linked = Set(plan.items.compactMap(\.artefactID))
        record.artefacts = artefacts.filter { $0.planID == plan.id || linked.contains($0.id) }
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
