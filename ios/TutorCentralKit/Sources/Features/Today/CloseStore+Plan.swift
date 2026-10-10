import Data
import Domain
import Foundation

/// The close from today's plan (plan Task 20): each student's checks or placement from the plan with no call, the
/// group's lines as a checklist, the homework sheet given; a student the plan left out closes with attendance alone.
public extension CloseStore {
    /// A group's lines (P10-Close): "Group 1 · Chemical reactions", one row per line.
    struct ChecklistCard: Identifiable, Hashable, Sendable {
        public let id: Int
        public let title: String
        public var rows: [ChecklistLine]
    }

    /// One line of the checklist: the words its students share, their names when not the whole group's.
    struct ChecklistLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let text: String
        public var done: Bool
        public let itemIDs: [UUID]
    }

    /// The quiet Plan in the top row shows.
    var hasPlan: Bool {
        !checklist.isEmpty
    }

    func toggle(line: UUID, in group: Int) {
        guard let card = checklist.firstIndex(where: { $0.id == group }),
              let row = checklist[card].rows.firstIndex(where: { $0.id == line }) else { return }
        checklist[card].rows[row].done.toggle()
    }

    /// "2 of 5".
    func countText(for group: Int) -> String {
        let rows = checklist.first { $0.id == group }?.rows ?? []
        return "\(rows.count(where: \.done)) of \(rows.count)"
    }

    /// "Homework given · sheet 1" from the plan's homework line; "Homework given" without one.
    func homeworkLabel(_ student: CloseStudent) -> String {
        guard let words = homeworkItem(student.id)?.words, words.hasPrefix("Homework ") else { return "Homework given" }
        return "Homework given · " + words.dropFirst("Homework ".count)
    }

    internal func homeworkItem(_ student: UUID) -> PlanItem? {
        plan?.items(of: student).first { $0.kind == .homework && $0.skippedAt == nil }
    }

    /// The ticked lines' items of the students who came, for Done.
    internal var doneItems: [UUID] {
        let absent = Set(students.filter { !$0.present }.map(\.id))
        let owner = Dictionary(uniqueKeysWithValues: (plan?.items ?? []).map { ($0.id, $0.studentID) })
        return checklist.flatMap(\.rows).filter(\.done).flatMap(\.itemIDs).filter { item in
            guard let student = owner[item] ?? nil else { return true }
            return !absent.contains(student)
        }
    }

    // MARK: - Reading the plan

    /// The plan as read; a failed read keeps the copy (already shown).
    internal func readPlan() async {
        guard let plans else { return }
        do {
            if let read = try await plans.plan(centre: workspace.centre.id, classID: classID, date: day) {
                show(read)
            }
        } catch {
            return
        }
    }

    /// The plan's checklist, and the checks of each student still waiting for theirs.
    internal func show(_ read: PlanRecord) {
        let ticked = Set(checklist.flatMap(\.rows).filter(\.done).flatMap(\.itemIDs))
        plan = read
        checklist = Self.checklist(read, names: { self.register.student($0)?.firstName ?? "" }, ticked: ticked)
        for index in students.indices where students[index].checks == .loading {
            takePlanChecks(index)
        }
    }

    /// Once the books are read: the plan's checks again for each student not yet tapped (a placement groups by the
    /// book).
    internal func refreshPlanChecks() {
        for index in students.indices where Self.taps(students[index].checks).allSatisfy({ $0.tap == nil }) {
            takePlanChecks(index)
        }
    }

    private func takePlanChecks(_ index: Int) {
        let id = students[index].id
        guard let checks = planChecks(id) else { return }
        students[index].checks = checks
        if checks == .skipped, plan?.items(of: id).allSatisfy({ $0.skippedAt != nil }) == true {
            students[index].homeworkGiven = false
        }
    }

    /// A student's checks from the plan; nil for a student the plan does not have (Phase 11's way).
    internal func planChecks(_ student: UUID) -> CloseChecks? {
        guard let plan else { return nil }
        let items = plan.items(of: student)
        guard !items.isEmpty else { return nil }
        guard let line = items.first(where: { $0.kind == .check }), line.skippedAt == nil,
              items.contains(where: { $0.skippedAt == nil }) else { return .skipped }
        guard let artefact = plan.checks(for: student), case let .check(content) = artefact.content else {
            return nil
        }
        if artefact.kind == .placement || content.placement {
            return .placement(placement(content, student: student))
        }
        return .rows(content.questions.map { question in
            CheckLine(
                skillID: question.skillID, skill: question.skill, question: question.question, answer: question.answer,
                tap: nil, recorded: nil, isPlacement: false
            )
        })
    }

    /// The plan's placement as the student's book groups it: a subject per group, a row per question it has.
    private func placement(_ content: CheckContent, student: UUID) -> [PlacementSubject] {
        let groups = Placement.groups(chapters: chapters[student] ?? [], skills: skills[student] ?? [])
        let subjects = groups.compactMap { group -> PlacementSubject? in
            let rows = group.items.compactMap { item -> PlacementRow? in
                guard let question = content.questions.first(where: {
                    $0.skillID == item.skillID || $0.skill.caseInsensitiveCompare(item.skill) == .orderedSame
                }) else { return nil }
                return PlacementRow(
                    chapterID: item.chapterID, skillID: item.skillID, chapter: item.name, skill: item.skill,
                    question: question.question, answer: question.answer
                )
            }
            return rows.isEmpty ? nil : PlacementSubject(title: group.title, rows: rows, failure: nil)
        }
        guard subjects.isEmpty else { return subjects }
        // No book read (offline, or none yet): the questions as the plan has them.
        let rows = content.questions.map {
            PlacementRow(
                chapterID: $0.skillID, skillID: $0.skillID, chapter: $0.skill, skill: $0.skill, question: $0.question,
                answer: $0.answer
            )
        }
        return [PlacementSubject(title: "Placement", rows: rows, failure: nil)]
    }

    /// The skill a check row records on: the student's own of that id, else of that name; nil when they have none
    /// (a group's check made from another student's book, for a student without the book).
    internal func ownSkill(_ skillID: UUID, named name: String, student: UUID) -> Skill? {
        let own = skills[student] ?? []
        return own.first { $0.id == skillID }
            ?? own.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: - The checklist

    /// Per group, the lines of each kind in the plan's order: catch up, teach, practise, check, homework; lines with
    /// the same words are one row, named for their students unless the whole group shares it.
    internal nonisolated static func checklist(
        _ plan: PlanRecord, names: (UUID) -> String, ticked: Set<UUID>
    ) -> [ChecklistCard] {
        let kinds: [PlanLineKind] = [.catchUp, .teach, .practise, .check, .homework]
        return plan.groups.compactMap { group in
            let items = plan.items.filter { $0.groupNo == group.number && $0.studentID != nil && $0.skippedAt == nil }
            let members = Set(items.compactMap(\.studentID))
            let rows = kinds.flatMap { kind in
                let ofKind = items.filter { $0.kind == kind }
                var order: [String] = []
                for item in ofKind.sorted(by: { names($0.studentID ?? UUID()) < names($1.studentID ?? UUID()) })
                    where !order.contains(item.words) {
                    order.append(item.words)
                }
                return order.map { words in
                    let lines = ofKind.filter { $0.words == words }
                    let who = Set(lines.compactMap(\.studentID))
                    let named = who == members ? words
                        : words + " (" + who.map(names).sorted().joined(separator: ", ") + ")"
                    let ids = lines.map(\.id)
                    return ChecklistLine(
                        id: ids[0], text: named,
                        done: lines.allSatisfy { $0.doneAt != nil } || ids.allSatisfy(ticked.contains),
                        itemIDs: ids
                    )
                }
            }
            guard !rows.isEmpty else { return nil }
            let title = group.chapter.isEmpty ? "Group \(group.number)" : "Group \(group.number) · \(group.chapter)"
            return ChecklistCard(id: group.number, title: title, rows: rows)
        }
    }
}
