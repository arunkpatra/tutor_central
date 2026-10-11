import Data
import Domain
import Foundation

extension PlanMaker {
    /// A new batch's first checks (the owner, 2026-10-11): each member of a group /ai/plan named gets the named chapter
    /// (unless one of that name is theirs in the subject) and the skill in it, and their lines take the skill's id; a
    /// failed write leaves that member's lines as they were (the close matches by name).
    func writeNamedSkills(_ draft: PlanDraft, record: Record, centre: UUID) async -> PlanDraft {
        var own: [UUID: UUID] = [:]
        for group in draft.groups where group.examItemID == nil && !group.skill.isEmpty {
            for member in group.memberIDs {
                let chapters = (record.chapters[member] ?? []).filter { $0.subject == group.subject }
                let skills = record.skills[member] ?? []
                guard !skills.contains(where: { skill in chapters.contains { $0.id == skill.chapterID } }) else {
                    continue
                }
                own[member] = await writeSkill(
                    group,
                    member: member,
                    chapters: chapters,
                    skills: skills,
                    centre: centre
                )
            }
        }
        guard !own.isEmpty else { return draft }
        let lines = draft.lines.map { line in
            line.studentID.flatMap { own[$0] }
                .map { line.kind == .teach || line.kind == .check ? line.with(skillID: $0) : line }
                ?? line
        }
        return PlanDraft(
            classID: draft.classID, date: draft.date, groups: draft.groups, lines: lines, leftOut: draft.leftOut
        )
    }

    private func writeSkill(
        _ group: PlanGroup, member: UUID, chapters: [Chapter], skills: [Skill], centre: UUID
    ) async -> UUID? {
        do {
            if let chapter = chapters.first(where: { $0.name.caseInsensitiveCompare(group.chapter) == .orderedSame }) {
                if let skill = skills.first(where: { $0.chapterID == chapter.id && $0.name == group.skill }) {
                    return skill.id
                }
                return try await textbooks.addSkill(group.skill, chapter: chapter.id, student: member, centre: centre)
                    .id
            }
            let chapter = try await textbooks.addChapter(
                student: member, subject: group.subject, name: group.chapter, skills: [group.skill], centre: centre
            )
            return try await textbooks.skills(student: member).first { $0.chapterID == chapter.id }?.id
        } catch {
            return nil
        }
    }
}
