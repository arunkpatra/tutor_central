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

    /// A group the make could not name (/ai/plan away) is named at the next open (the owner, 2026-10-11): the name
    /// written to the plan (`name_plan_group`: the group and its teach lines) and each member's chapter and skill, then
    /// the plan read again so its material is made; a second failure leaves it as it was, with nothing written.
    func nameUnnamed(_ plan: PlanRecord, batch: PlanBatch, record: Record) async -> PlanRecord {
        guard plan.sessionID == nil,
              plan.groups.contains(where: { $0.skill.isEmpty && $0.examItemID == nil }) else { return plan }
        let draft = plan.asDraft
        let named = await named(draft, members: batch.members, centre: batch.centre)
        var wrote = false
        for group in named.groups {
            guard let before = draft.groups.first(where: { $0.number == group.number }), before.skill.isEmpty,
                  !group.skill.isEmpty,
                  await (try? plans.nameGroup(
                      plan: plan.id, group: group.number, chapter: group.chapter, skill: group.skill,
                      centre: batch.centre
                  )) != nil else { continue }
            wrote = true
        }
        guard wrote else { return plan }
        _ = await writeNamedSkills(named, record: record, centre: batch.centre)
        let read = await (try? plans.plan(id: plan.id, centre: batch.centre)) ?? nil
        if let read {
            cache?.keep(read, at: now())
        }
        return read ?? plan
    }
}
