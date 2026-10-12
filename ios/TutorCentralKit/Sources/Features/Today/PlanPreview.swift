import Data
import Domain
import Foundation

/// The batch a plan is previewed for: the batch, its members, the day and the centre.
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

/// What the phone still reads around the day's plan, which the server makes (Phase 18, D70): the rules' groups for the
/// Change sheet's preview (nothing written, no AI), the members' subjects for its menus, whether the batch was closed
/// or is wholly on holiday, and each member's book kept for the close offline.
public final class PlanPreview: Sendable {
    let plans: any PlansRepository
    let textbooks: any TextbooksRepository
    let attendance: any AttendanceRepository
    let schoolItems: any SchoolItemsRepository
    let cache: PlanCache?
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        plans: any PlansRepository, textbooks: any TextbooksRepository, attendance: any AttendanceRepository,
        schoolItems: any SchoolItemsRepository, cache: PlanCache?, now: @escaping @Sendable () -> Date,
        calendar: Calendar
    ) {
        self.plans = plans
        self.textbooks = textbooks
        self.attendance = attendance
        self.schoolItems = schoolItems
        self.cache = cache
        self.now = now
        self.calendar = calendar
    }

    /// The rules alone (no write): what the Change sheet previews.
    public func draft(_ batch: PlanBatch, choices: PlanChoices?) async throws -> PlanDraft {
        let record = try await read(members: batch.members, date: batch.date, centre: batch.centre)
        return PlanRules.plan(input(batch, record, choices))
    }

    /// Each member's chapters and skills kept on this iPhone, which the close offline reads to record the plan's checks
    /// on each student's own skills; a member whose read fails keeps the copy before.
    public func keepBooks(of members: [Student]) async {
        await withTaskGroup(of: Void.self) { group in
            for member in members {
                group.addTask { [textbooks, cache, now] in
                    async let chapters = textbooks.chapters(student: member.id)
                    async let skills = textbooks.skills(student: member.id)
                    guard let book = try? await BookCopy(chapters: chapters, skills: skills) else { return }
                    cache?.keepBook(book, student: member.id, at: now())
                }
            }
        }
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

    /// The batch's session of the day was closed: no plan is asked for.
    public func closed(classID: UUID, date: Day, centre: UUID) async -> Bool {
        let sessions = await (try? attendance.sessions(centre: centre, month: date.period)) ?? []
        return sessions.contains { $0.classID == classID && $0.date == date && $0.closedAt != nil }
    }

    /// Every member is on holiday on the batch's day: no plan.
    public func wholeBatchOnHoliday(_ batch: PlanBatch) async -> Bool {
        guard !batch.members.isEmpty,
              let items = try? await schoolItems.items(centre: batch.centre) else { return false }
        let holidays = items.filter { $0.kind == .holiday }
        return batch.members.allSatisfy {
            HolidayRules.onHoliday($0, on: batch.date, items: holidays, students: batch.members)
        }
    }

    /// The centre's school items (the exams' dates for an exam group's countdown).
    public func items(centre: UUID) async throws -> [SchoolItem] {
        try await schoolItems.items(centre: centre)
    }

    // MARK: - The record

    /// What the rules read: each member's chapters and skills (read together), the batch's sessions this month and
    /// last, the school items, and each member's used gap report.
    struct Record: Sendable {
        var chapters: [UUID: [Chapter]] = [:]
        var skills: [UUID: [Skill]] = [:]
        var sessions: [AttendanceSession] = []
        var items: [SchoolItem] = []
        var gapReports: [UUID: GapReportContent] = [:]
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
        record.items = await (try? schoolItems.items(centre: centre)) ?? []
        record.gapReports = await gapReports(items: record.items, members: members, date: date, centre: centre)
        return record
    }

    private func input(_ batch: PlanBatch, _ record: Record, _ choices: PlanChoices?) -> PlanInput {
        let exams = exams(for: batch, record: record)
        return PlanInput(
            classroom: batch.classroom, date: batch.date, students: batch.members, chapters: record.chapters,
            skills: record.skills, sessions: record.sessions,
            schoolItems: SchoolItemRules.hints(
                record.items, students: batch.members, today: batch.date, calendar: calendar
            ),
            now: now(), calendar: calendar, groupCount: choices?.groups, subjects: choices?.subjects ?? [:],
            revisions: exams.revisions, holidays: exams.holidays
        )
    }
}
