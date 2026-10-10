import Data
import Domain
import Foundation

/// A row of the Change sheet (P10-Today-Plan-Change): "Group 1 · Class 8" with its subject and the subjects offered.
public struct ChangeRow: Identifiable, Hashable, Sendable {
    public var id: Int {
        number
    }

    public let number: Int
    public let title: String
    public let subject: String
    public let offered: [String]
}

/// Changing the plan where it appears (spec section 2; plan decision 17): plain updates as the user; offline each is
/// refused in words and nothing changes.
public extension PlanStore {
    internal static let changeFailed = "Couldn't change the plan. Nothing was changed."

    func move(student: UUID, to group: Int) async {
        guard let plan = record, await allowed() else { return }
        let theirs = plan.items(of: student)
        guard let from = theirs.first?.groupNo, from != group else { return }
        do {
            try await plans.move(items: theirs.map(\.id), to: group, from: from, centre: centre)
            var changed = plan
            for index in changed.items.indices where changed.items[index].studentID == student {
                changed.items[index].groupNo = group
                changed.items[index].movedFrom = from
            }
            changed = try await relink(student, in: changed, to: group)
            keepShown(changed)
        } catch {
            message = Self.changeFailed
        }
    }

    func skipCheck(student: UUID) async {
        await skip(student: student, kind: .check)
    }

    func skipHomework(student: UUID) async {
        await skip(student: student, kind: .homework)
    }

    /// The student's lines skipped for today: they close with attendance alone (no checks, homework off).
    func leaveOut(student: UUID) async {
        guard var plan = record, await allowed() else { return }
        do {
            try await plans.leaveOut(student: student, plan: plan.id, centre: centre)
            for index in plan.items.indices where plan.items[index].studentID == student {
                plan.items[index].skippedAt = now()
            }
            keepShown(plan)
        } catch {
            message = Self.changeFailed
        }
    }

    /// "Keep this for Wednesdays": the weekday's group count and subjects on the batch.
    func keep(choices: PlanChoices, for weekday: Weekday) async {
        guard await allowed() else { return }
        let count = choices.groups ?? groups.count
        let subjects = (1 ... max(count, 1)).map { choices.subjects[$0] ?? changeChoices.subjects[$0] ?? "" }
        do {
            try await classes.setPlanPattern(
                PlanPattern(groups: count, subjects: subjects), weekday: weekday, classID: classID
            )
        } catch {
            message = Self.changeFailed
        }
    }

    /// Use this plan: today's plan made again with the sheet's choices (the material made again).
    func useToday(choices: PlanChoices?) async {
        guard await allowed() else { return }
        await make(choices: choices)
    }

    /// Cancel on the planning card: the run stops; the plan is made at the next open.
    func cancel() {
        generation += 1
        run?.cancel()
        run = nil
        show(record.map(State.made) ?? .none)
    }

    /// The sheet's starting values: the plan's group count and each group's subject.
    var changeChoices: PlanChoices {
        let groups = record?.groups ?? []
        return PlanChoices(
            groups: groups.count, subjects: Dictionary(uniqueKeysWithValues: groups.map { ($0.number, $0.subject) })
        )
    }

    /// The subjects a group can take today: its members' subjects, the batch's, and the one it has.
    func subjectsOffered(group: Int) -> [String] {
        let members = record?.groups.first { $0.number == group }?.memberIDs ?? []
        let books = members.flatMap { member in subjects[member] ?? [] }
        let current = record?.groups.first { $0.number == group }?.subject
        let all = Set(books + [register.classroom(classID)?.subject, current].compactMap(\.self))
        return all.sorted()
    }

    /// The sheet's rows for a choice of group count: the rules' groups for it (nothing is written).
    func preview(_ choices: PlanChoices) async -> [ChangeRow] {
        guard let classroom = register.classroom(classID) else { return [] }
        let batch = PlanBatch(
            classroom: classroom, members: register.members(of: classID), date: today, centre: centre
        )
        guard let draft = try? await maker.draft(batch, choices: choices) else { return [] }
        return draft.groups.map { group in
            ChangeRow(
                number: group.number,
                title: ["Group \(group.number)", Self.classes(group.classLevels)].compactMap(\.self)
                    .joined(separator: " · "),
                subject: group.subject, offered: Array(Set(subjectsOffered(group: group.number) + [group.subject]))
                    .sorted()
            )
        }
    }

    // MARK: - Helpers

    /// Online, or refused in words.
    private func allowed() async -> Bool {
        guard await online() else {
            message = OfflineRefusal.words(for: .changePlan)
            return false
        }
        return true
    }

    private func skip(student: UUID, kind: PlanLineKind) async {
        guard var plan = record, await allowed(),
              let index = plan.items.firstIndex(where: { $0.studentID == student && $0.kind == kind }) else { return }
        do {
            try await plans.skip(item: plan.items[index].id, centre: centre)
            plan.items[index].skippedAt = now()
            keepShown(plan)
        } catch {
            message = Self.changeFailed
        }
    }

    /// A moved student's set, checks (unless their own) and sheet follow the new group's, where those are made.
    private func relink(_ student: UUID, in plan: PlanRecord, to group: Int) async throws -> PlanRecord {
        var plan = plan
        let own = plan.artefacts.contains { $0.studentID == student }
        let targets: [(PlanLineKind, Artefact?)] = [
            (.practise, plan.artefact(group: group, kind: .sheet, homework: false)),
            (.homework, plan.artefact(group: group, kind: .sheet, homework: true)),
            (.check, own ? nil : plan.artefact(group: group, kind: .check)),
        ]
        for (kind, artefact) in targets {
            guard let artefact,
                  let index = plan.items.firstIndex(where: { $0.studentID == student && $0.kind == kind })
            else { continue }
            try await plans.link(items: [plan.items[index].id], to: artefact.id, centre: centre)
            plan.items[index].artefactID = artefact.id
        }
        return plan
    }

    /// The changed plan on screen and in the copy on this iPhone; a run still landing keeps it.
    private func keepShown(_ plan: PlanRecord) {
        show(planning ? .planning(plan) : .made(plan))
        cache?.keep(plan, at: now())
    }
}
