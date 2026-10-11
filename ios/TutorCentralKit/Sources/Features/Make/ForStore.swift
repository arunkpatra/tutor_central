import Data
import Domain
import Foundation
import Observation

/// The For sheet (P10-Make-For): a student, one of today's groups, a batch, or a class level on its own.
@MainActor @Observable public final class ForStore {
    public enum Segment: CaseIterable, Hashable, Sendable {
        case student, group, batch, level

        public var title: String {
            switch self {
            case .student: "Student"
            case .group: "Group"
            case .batch: "Batch"
            case .level: "Class"
            }
        }
    }

    public struct Row: Identifiable, Hashable, Sendable {
        public var id: MakeTarget {
            target
        }

        public let target: MakeTarget
        public let title: String
        public let line: String
    }

    public var segment: Segment
    public private(set) var groups: [Row] = []
    public private(set) var loaded = false
    public let chosen: MakeTarget?
    let context: MakeContext

    init(context: MakeContext, chosen: MakeTarget?) {
        self.context = context
        self.chosen = chosen
        segment = switch chosen {
        case .group?: .group
        case .batch?: .batch
        case .classLevel?: .level
        default: .student
        }
    }

    public static let groupsEmptyTitle = "No groups today"
    public let groupsEmptyLine = "Open Today to make the plan."
    public static let footnote = "Today's groups. A sheet for a group is made at the group's level; for a class alone, "
        + "at the class's."

    public func load() async {
        await context.register.loadIfNeeded()
        let register = context.register
        groups = await TodayGroups.read(context).map { today in
            let group = today.group
            let names = group.memberIDs.compactMap { register.student($0)?.firstName }.joined(separator: ", ")
            let levels = Array(Set(group.memberIDs.compactMap { register.student($0)?.classLevel })).sorted()
            let classes = (levels.isEmpty ? group.classLevels.sorted() : levels).map(\.title).joined(separator: " and ")
            let classSubject = [classes, group.subject == group.chapter ? "" : group.subject]
                .filter { !$0.isEmpty }.joined(separator: " ")
            return Row(
                target: .group(plan: today.planID, number: group.number),
                title: ["Group \(group.number)", group.chapter.isEmpty ? group.skill : group.chapter]
                    .filter { !$0.isEmpty }.joined(separator: " · "),
                line: [names, classSubject, "today's plan"].filter { !$0.isEmpty }.joined(separator: " · ")
            )
        }
        loaded = true
    }

    public var students: [Student] {
        context.register.activeStudents
    }

    public var batches: [Row] {
        context.register.activeClasses.map { batch in
            let count = context.register.members(of: batch.id).count
            return Row(target: .batch(batch.id), title: batch.name, line: "\(count) student\(count == 1 ? "" : "s")")
        }
    }

    /// LKG to 10, the levels the centre's students are in first.
    public var levels: [ClassLevel] {
        let held = Set(students.compactMap(\.classLevel))
        return ClassLevel.allCases.filter(held.contains) + ClassLevel.allCases.filter { !held.contains($0) }
    }

    public func className(_ id: UUID?) -> String? {
        context.register.classroom(id)?.name
    }
}
