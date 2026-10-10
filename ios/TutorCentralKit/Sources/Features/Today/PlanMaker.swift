import Data
import Domain
import Foundation

/// Today's choices from the Change sheet: the group count and each group's subject; nil fields leave them to the
/// batch's pattern and the rules.
public struct PlanChoices: Hashable, Sendable {
    public var groups: Int?
    public var subjects: [Int: String]

    public init(groups: Int?, subjects: [Int: String]) {
        self.groups = groups
        self.subjects = subjects
    }
}

/// The batch a plan is made for: the batch, its members, the day and the centre.
public struct PlanBatch: Sendable {
    public let classroom: Classroom
    public let members: [Student]
    public let date: Day
    public let centre: UUID

    public init(classroom: Classroom, members: [Student], date: Day, centre: UUID) {
        self.classroom = classroom
        self.members = members
        self.date = date
        self.centre = centre
    }
}

/// What one run works from: the draft, the record it read, the centre.
struct PlanWork: Sendable {
    let draft: PlanDraft
    let record: PlanMaker.Record
    let centre: UUID
}

/// Makes the day's plan for one batch and its material, as the user (D60): the rules, the write, then the artefacts in
/// the budget's order, each kept as it lands. Shared by Today's open and the background refresh.
public final class PlanMaker: Sendable {
    /// What the maker reports as it goes: the plan written (its lines show), then each artefact kept.
    public enum Progress: Sendable {
        case written(PlanRecord)
        case kept(Artefact, PlanRecord)
        case finished(PlanRecord)
        case failed(String)

        public var name: String {
            switch self {
            case .written: "written"
            case .kept: "kept"
            case .finished: "finished"
            case .failed: "failed"
            }
        }
    }

    let plans: any PlansRepository
    let textbooks: any TextbooksRepository
    let attendance: any AttendanceRepository
    let ai: any AIRepository
    let cache: PlanCache?
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        plans: any PlansRepository, textbooks: any TextbooksRepository, attendance: any AttendanceRepository,
        ai: any AIRepository, cache: PlanCache?, now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.plans = plans
        self.textbooks = textbooks
        self.attendance = attendance
        self.ai = ai
        self.cache = cache
        self.now = now
        self.calendar = calendar
    }

    /// The words when the record could not be read: nothing is written, the next open tries again.
    static let readFailed = "Couldn't make today's plan. Check your connection and try again."

    /// Makes the plan for the batch on `date`; the choices come from the Change sheet, else the batch's pattern.
    public func make(
        _ batch: PlanBatch, choices: PlanChoices?, progress: @escaping @Sendable (Progress) async -> Void
    ) async {
        let (members, centre) = (batch.members, batch.centre)
        let record: Record
        do {
            record = try await read(members: members, date: batch.date, centre: centre)
        } catch {
            await progress(.failed(Self.readFailed))
            return
        }
        var draft = PlanRules.plan(input(batch, record, choices))
        draft = await named(draft, members: members, centre: centre)
        let briefs = await (try? plans.briefChapters(centre: centre)) ?? []
        draft = draft.addingBriefs(for: briefs)
        guard !Task.isCancelled else { return }
        var plan: PlanRecord
        do {
            plan = try await plans.make(draft, centre: centre)
        } catch {
            await progress(.failed(Self.readFailed))
            return
        }
        cache?.keep(plan, at: now())
        await progress(.written(plan))
        let requests = ArtefactBudget.requests(
            for: draft, students: Self.byID(members), spacedSkills: spaced(draft, record), briefsMade: briefs
        )
        let work = PlanWork(draft: draft, record: record, centre: centre)
        plan = await makeAll(requests, into: plan, work: work, progress: progress)
        guard !Task.isCancelled else { return }
        await progress(.finished(plan))
    }

    /// The material a plan already written is still missing (a refresh iOS stopped part-way, a call that failed), made
    /// into the plan as it stands.
    public func complete(
        _ plan: PlanRecord, members: [Student], centre: UUID, progress: @escaping @Sendable (Progress) async -> Void
    ) async {
        guard let record = try? await read(members: members, date: plan.date, centre: centre) else {
            await progress(.finished(plan))
            return
        }
        let draft = plan.asDraft
        let briefs = await (try? plans.briefChapters(centre: centre)) ?? []
        let missing = ArtefactBudget.requests(
            for: draft, students: Self.byID(members), spacedSkills: spaced(draft, record), briefsMade: briefs
        ).filter { request in
            let place = place(of: request, in: draft)
            return plan.hasLine(for: place) && !plan.fills(place)
        }
        let work = PlanWork(draft: draft, record: record, centre: centre)
        let made = await makeAll(missing, into: plan, work: work, progress: progress)
        guard !Task.isCancelled else { return }
        await progress(.finished(made))
    }

    /// Each request made and kept in order, the copy kept and the progress told as each lands; a failed call is
    /// skipped and the rest goes on; a cancelled run stops before its next keep.
    private func makeAll(
        _ requests: [ArtefactRequest], into plan: PlanRecord, work: PlanWork,
        progress: @escaping @Sendable (Progress) async -> Void
    ) async -> PlanRecord {
        var plan = plan
        for request in requests {
            guard !Task.isCancelled else { break }
            guard let shaped = await made(request, work: work),
                  !Task.isCancelled,
                  let kept = try? await plans.keep(shaped.0, to: shaped.1.on(plan.id), centre: work.centre)
            else { continue }
            plan = plan.keeping(kept, link: shaped.1)
            cache?.keep(plan, at: now())
            await progress(.kept(kept, plan))
        }
        return plan
    }

    private static func byID(_ members: [Student]) -> [UUID: Student] {
        Dictionary(members.map { ($0.id, $0) }) { first, _ in first }
    }

    /// The rules alone (no write): what the Change sheet previews, and the tests read.
    public func draft(_ batch: PlanBatch, choices: PlanChoices?) async throws -> PlanDraft {
        let record = try await read(members: batch.members, date: batch.date, centre: batch.centre)
        return PlanRules.plan(input(batch, record, choices))
    }

    /// Each member's subjects, from their chapters (the Change sheet's menus); a member whose read fails has none.
    public func subjects(of members: [Student]) async -> [UUID: [String]] {
        await withTaskGroup(of: (UUID, [String]).self) { group in
            for member in members {
                group.addTask { [textbooks] in
                    let chapters = await (try? textbooks.chapters(student: member.id)) ?? []
                    return (member.id, Array(Set(chapters.map(\.subject))).sorted())
                }
            }
            var all: [UUID: [String]] = [:]
            for await (id, subjects) in group {
                all[id] = subjects
            }
            return all
        }
    }

    /// The batch's session of the day was closed: no plan is made for it.
    public func closed(classID: UUID, date: Day, centre: UUID) async -> Bool {
        let sessions = await (try? attendance.sessions(centre: centre, month: date.period)) ?? []
        return sessions.contains { $0.classID == classID && $0.date == date && $0.closedAt != nil }
    }

    // MARK: - The record

    /// What the rules read: each member's chapters and skills (read together), the batch's sessions this month and
    /// last.
    struct Record: Sendable {
        var chapters: [UUID: [Chapter]] = [:]
        var skills: [UUID: [Skill]] = [:]
        var sessions: [AttendanceSession] = []
    }

    private func read(members: [Student], date: Day, centre: UUID) async throws -> Record {
        async let thisMonth = attendance.sessions(centre: centre, month: date.period)
        async let lastMonth = attendance.sessions(
            centre: centre,
            month: date.adding(days: -date.day, calendar: calendar).period
        )
        var record = Record()
        try await withThrowingTaskGroup(of: (UUID, [Chapter], [Skill]).self) { group in
            for member in members {
                group.addTask { [textbooks] in
                    async let chapters = textbooks.chapters(student: member.id)
                    async let skills = textbooks.skills(student: member.id)
                    return try await (member.id, chapters, skills)
                }
            }
            for try await (id, chapters, skills) in group {
                record.chapters[id] = chapters
                record.skills[id] = skills
            }
        }
        record.sessions = try await thisMonth + lastMonth
        return record
    }

    private func input(_ batch: PlanBatch, _ record: Record, _ choices: PlanChoices?) -> PlanInput {
        PlanInput(
            classroom: batch.classroom, date: batch.date, students: batch.members, chapters: record.chapters,
            skills: record.skills,
            sessions: record.sessions, schoolItems: [], now: now(), calendar: calendar, groupCount: choices?.groups,
            subjects: choices?.subjects ?? [:]
        )
    }

    /// The groups whose record names no skill, named by /ai/plan for the month; a failure leaves them unnamed (their
    /// material is made at the next open).
    private func named(_ draft: PlanDraft, members: [Student], centre: UUID) async -> PlanDraft {
        let unnamed = draft.groups.filter(\.skill.isEmpty)
        guard !unnamed.isEmpty else { return draft }
        let levels = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0.classLevel) })
        let asked = unnamed.map { group in
            PlanTopicGroup(
                groupNo: group.number,
                classLevel: group.memberIDs.compactMap { levels[$0] ?? nil }.max() ?? .five,
                subject: group.subject
            )
        }
        let month = draft.date.month
        guard let topics = try? await ai.planTopics(
            classID: draft.classID, date: draft.date, month: month, groups: asked, centre: centre
        ) else { return draft }
        return draft
            .naming(Dictionary(topics.map { ($0.groupNo, (chapter: $0.chapter, skill: $0.skill)) }) { first, _ in
                first
            })
    }

    /// Each member's spaced pick in their group's subject.
    private func spaced(_ draft: PlanDraft, _ record: Record) -> [UUID: [Skill]] {
        var picks: [UUID: [Skill]] = [:]
        for group in draft.groups {
            for member in group.memberIDs {
                let chapters = (record.chapters[member] ?? []).filter { $0.subject == group.subject }
                let ids = Set(chapters.map(\.id))
                let skills = (record.skills[member] ?? []).filter { ids.contains($0.chapterID) }
                picks[member] = SpacedQueue.pick(skills: skills, chapters: chapters, now: now(), calendar: calendar)
            }
        }
        return picks
    }
}
