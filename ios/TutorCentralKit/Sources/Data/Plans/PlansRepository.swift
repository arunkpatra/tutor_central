import Domain
import Foundation

/// The day's plans and their artefacts (`plans`, `plan_items`, `artefacts`; migrations 0010 and 0019). RLS keeps every
/// call inside the member's centre; the writes are the app's, as the user (D60).
public protocol PlansRepository: Sendable {
    /// The day's plan for a batch with its items and the artefacts its items link; nil when none was made.
    func plan(centre: UUID, classID: UUID, date: Day) async throws -> PlanRecord?
    /// A plan by its id (an artefact's screen reads the plan it belongs to); nil when gone.
    func plan(id: UUID, centre: UUID) async throws -> PlanRecord?
    /// `make_plan`: the draft written (a second call replaces the day's plan); the record with its item ids, no
    /// artefacts.
    func make(_ draft: PlanDraft, centre: UUID) async throws -> PlanRecord
    /// `keep_artefact`: the artefact written and linked to the group's items of the kind (student nil) or one
    /// student's.
    func keep(_ artefact: NewArtefact, to link: ArtefactLink, centre: UUID) async throws -> Artefact
    func artefact(id: UUID, centre: UUID) async throws -> Artefact?
    /// The chapters a brief was made for (the budget's "asked before").
    func briefChapters(centre: UUID) async throws -> Set<String>
    func skip(item: UUID, centre: UUID) async throws
    func move(items: [UUID], to group: Int, from: Int, centre: UUID) async throws
    /// The student's lines skipped for today: they close with attendance alone.
    func leaveOut(student: UUID, plan: UUID, centre: UUID) async throws
    /// Lines pointed at an artefact already kept (a moved student's set, checks and sheet: the new group's).
    func link(items: [UUID], to artefact: UUID?, centre: UUID) async throws
}

/// Where a kept artefact is linked: the plan's items of a kind in a group (student nil), or one student's.
public struct ArtefactLink: Hashable, Sendable {
    public let plan: UUID
    public let group: Int
    public let student: UUID?
    public let itemKind: PlanLineKind

    public init(plan: UUID, group: Int, student: UUID?, itemKind: PlanLineKind) {
        self.plan = plan
        self.group = group
        self.student = student
        self.itemKind = itemKind
    }
}

/// An artefact as the app writes it (the API's result and its generation id, or the tutor's own).
public struct NewArtefact: Hashable, Sendable {
    public let kind: ArtefactKind
    public let source: ArtefactSource
    public let title: String
    public let content: ArtefactContent
    public let photoPath: String?
    public let generationID: UUID?
    public let regeneratedFrom: UUID?

    public init(
        kind: ArtefactKind, source: ArtefactSource, title: String, content: ArtefactContent, photoPath: String?,
        generationID: UUID?, regeneratedFrom: UUID?
    ) {
        self.kind = kind
        self.source = source
        self.title = title
        self.content = content
        self.photoPath = photoPath
        self.generationID = generationID
        self.regeneratedFrom = regeneratedFrom
    }
}

extension PlanRecord {
    /// The artefacts the items link (a regenerated one stays in the record, unlinked, and is left out here).
    func keepingLinkedArtefacts() -> PlanRecord {
        var record = self
        let linked = Set(items.compactMap(\.artefactID))
        record.artefacts = artefacts.filter { linked.contains($0.id) }
        return record
    }
}
