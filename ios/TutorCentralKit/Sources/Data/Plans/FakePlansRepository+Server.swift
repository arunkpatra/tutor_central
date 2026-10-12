import Domain
import Foundation

/// What the server's plan job does (Phase 18), for `bun shots` and the tests: the rules' draft written with its unnamed
/// groups named and a brief line where one is due, then each group's material kept from the samples (the set, the
/// sheet, the checks, the worked example, the brief). A figure, a mock and a placement are left unmade.
public extension FakePlansRepository {
    /// `levels` names each member's class for the topics; `material` false writes the plan alone (its marks on their
    /// way
    /// while the job is live).
    func serve(
        _ draft: PlanDraft,
        levels: [UUID: ClassLevel],
        material: Bool,
        centre: UUID
    ) async throws -> PlanRecord {
        let topics = draft.groups.filter(\.skill.isEmpty).map { group in
            let level = group.memberIDs.compactMap { levels[$0] }.max() ?? .five
            return (group.number, AISamples.topic(classLevel: level, subject: group.subject))
        }
        let named = await draft.naming(Dictionary(topics) { first, _ in first })
            .addingBriefs(for: (try? briefChapters(centre: centre)) ?? [])
        var plan = try await make(named, centre: centre)
        guard material else { return plan }
        for group in plan.groups {
            for (artefact, kind) in Self.material(for: group, lines: plan.items.filter { $0.groupNo == group.number }) {
                _ = try await keep(
                    artefact, to: ArtefactLink(plan: plan.id, group: group.number, student: nil, itemKind: kind),
                    centre: centre
                )
            }
        }
        plan = try await self.plan(id: plan.id, centre: centre) ?? plan
        return plan
    }

    /// The group's material for the lines it has.
    private static func material(for group: PlanGroup, lines: [PlanItem]) -> [(NewArtefact, PlanLineKind)] {
        let has = { (kind: PlanLineKind) in lines.contains { $0.kind == kind && $0.words != PlanRules.mockLine } }
        let made = { (kind: ArtefactKind, title: String, content: ArtefactContent) in
            NewArtefact(
                kind: kind, source: .made, title: title, content: content, photoPath: nil, generationID: nil,
                regeneratedFrom: nil
            )
        }
        var all: [(NewArtefact, PlanLineKind)] = []
        if has(.practise) {
            let set = AISamples.sheet(questions: 6, forHomework: false, light: false)
            all.append((made(.sheet, "\(group.skill) · set 1", .sheet(set)), .practise))
        }
        if has(.homework) {
            let sheet = AISamples.sheet(questions: 6, forHomework: true, light: false)
            all.append((made(.sheet, "\(group.skill) · sheet 1", .sheet(sheet)), .homework))
        }
        if lines.contains(where: { $0.kind == .check && !$0.words.hasPrefix("Placement") }) {
            let questions = AISamples.checks(for: [group.skill]).map {
                CheckContent.Question(skillID: UUID(), skill: $0.skill, question: $0.question, answer: $0.answer)
            }
            let checks = CheckContent(questions: questions, placement: false)
            all.append((made(.check, "Checks · \(group.skill)", .check(checks)), .check))
        }
        if has(.workedExample) {
            all.append((made(.workedExample, group.skill, .workedExample(AISamples.workedExample)), .workedExample))
        }
        if lines.contains(where: { $0.kind == .brief && $0.studentID == nil }) {
            all.append((made(.brief, PlanRules.briefPrefix + group.chapter, .brief(AISamples.brief)), .brief))
        }
        return all
    }
}
