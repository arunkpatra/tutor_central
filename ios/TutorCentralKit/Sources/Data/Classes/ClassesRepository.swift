import Domain
import Foundation

/// The centre's classes. RLS keeps every call inside the member's centre.
public protocol ClassesRepository: Sendable {
    /// Archived included, by name.
    func classes(centre: UUID) async throws -> [Classroom]
    func create(_ draft: ClassroomDraft, centre: UUID) async throws -> Classroom
    func update(id: UUID, with draft: ClassroomDraft) async throws -> Classroom
    /// `archive_class`: the class is archived and its students are left without a class, in one transaction.
    func archive(id: UUID) async throws
    /// The batch's kept group count (`classes.plan_groups`); nil lets the plan's rules decide.
    func setPlanGroups(_ count: Int?, classID: UUID) async throws
    /// "Keep this for Wednesdays": the weekday's choices in `classes.plan_pattern`; nil removes them.
    func setPlanPattern(_ pattern: PlanPattern?, weekday: Weekday, classID: UUID) async throws
}
