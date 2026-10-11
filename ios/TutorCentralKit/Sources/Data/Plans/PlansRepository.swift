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
    /// The exam's mock, the newest when made again; nil before it is made.
    func mock(for item: UUID, centre: UUID) async throws -> Artefact?
    /// The student's gap report for the exam, the newest; nil before it is made.
    func gapReport(for item: UUID, student: UUID, centre: UUID) async throws -> Artefact?
    /// Every artefact kept for the exam, newest first.
    func artefacts(for item: UUID, centre: UUID) async throws -> [Artefact]
    /// The content replaced (Use this plan marks a gap report used).
    func setContent(_ content: ArtefactContent, artefact: UUID, centre: UUID) async throws
    /// `name_plan_group` (migration 0021): a group /ai/plan could not name at the make, named later; links untouched.
    func nameGroup(plan: UUID, group: Int, chapter: String, skill: String, centre: UUID) async throws
    /// The students' weekly notes and can-now-dos kept since a moment, newest first (Phase 14).
    func notes(centre: UUID, students: [UUID], since: Date) async throws -> [Artefact]
}

public extension PlansRepository {
    /// `keep_artefact` for a student's note: no plan, no exam, no line linked (as a gap report's keep).
    func keepNote(_ note: NewNote, centre: UUID) async throws -> Artefact {
        try await keep(note.artefact, to: note.link, centre: centre)
    }
}

/// A weekly note or can-now-do before it is kept (plan/phase-14-plan.md decision 1).
public struct NewNote: Hashable, Sendable {
    public let studentID: UUID
    /// `.note` or `.canDo`.
    public let kind: ArtefactKind
    public let title: String
    public let content: NoteContent
    public let regeneratedFrom: UUID?

    public init(studentID: UUID, kind: ArtefactKind, title: String, content: NoteContent, regeneratedFrom: UUID?) {
        self.studentID = studentID
        self.kind = kind
        self.title = title
        self.content = content
        self.regeneratedFrom = regeneratedFrom
    }

    var artefact: NewArtefact {
        NewArtefact(
            kind: kind, source: .made, title: title, content: .note(content), photoPath: nil,
            generationID: content.generationID, regeneratedFrom: regeneratedFrom
        )
    }

    var link: ArtefactLink {
        ArtefactLink(plan: nil, group: 0, student: studentID, itemKind: .practise)
    }
}

/// Where a kept artefact is linked: the plan's items of a kind in a group (student nil), or one student's; and the
/// exam it serves (a mock or a gap report, with no plan: no line is linked).
public struct ArtefactLink: Hashable, Sendable {
    public let plan: UUID?
    public let group: Int
    public let student: UUID?
    public let itemKind: PlanLineKind
    public let schoolItem: UUID?

    public init(plan: UUID?, group: Int, student: UUID?, itemKind: PlanLineKind, schoolItem: UUID? = nil) {
        self.plan = plan
        self.group = group
        self.student = student
        self.itemKind = itemKind
        self.schoolItem = schoolItem
    }

    /// An exam's artefact kept with no plan: the mock (no student) or a student's gap report.
    public init(item: UUID, student: UUID?) {
        self.init(plan: nil, group: 0, student: student, itemKind: .practise, schoolItem: item)
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
