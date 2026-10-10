import DesignSystem
import Domain
import Foundation

/// The plan's cards from its record (P10-Today-Plan, -Changed): a group's head, its marks, a line per student.
extension PlanStore {
    static let briefLine = "Five minutes · three common mistakes · the worked example to use"

    func cards(_ plan: PlanRecord) -> [GroupCardModel] {
        plan.groups.map { group in
            let lines = studentLines(plan, group: group.number)
            return GroupCardModel(
                id: group.number,
                title: group.chapter.isEmpty ? "Group \(group.number)" : "Group \(group.number) · \(group.chapter)",
                line: headLine(group, members: lines.map(\.id)),
                marks: marks(plan, group: group),
                lines: lines
            )
        }
    }

    func briefs(_ plan: PlanRecord) -> [BriefRowModel] {
        plan.items.filter { $0.kind == .brief && $0.studentID == nil }.map { item in
            BriefRowModel(
                title: item.words, line: Self.briefLine, artefactID: item.artefactID, afterGroup: item.groupNo
            )
        }
    }

    /// "Class 8 Science · 3 students"; a ladder's group, whose subject is its chapter, "Class 2 · 1 student".
    private func headLine(_ group: PlanGroup, members: [UUID]) -> String {
        let levels = Array(Set(members.compactMap { register.student($0)?.classLevel })).sorted()
        let classes = Self.classes(levels)
        let subject = group.subject == group.chapter ? nil : group.subject
        let what = [classes, subject].compactMap(\.self).joined(separator: " ")
        let count = members.count == 1 ? "1 student" : "\(members.count) students"
        return what.isEmpty ? count : "\(what) · \(count)"
    }

    /// "Class 8", "Class 7 and 8", "UKG and Class 1".
    static func classes(_ levels: [ClassLevel]) -> String? {
        guard let first = levels.first else { return nil }
        let rest = levels.dropFirst()
        guard !rest.isEmpty else { return first.title }
        let numbered = levels.allSatisfy { $0 != .lkg && $0 != .ukg }
        let names = numbered ? [first.title] + rest.map(\.rawValue) : levels.map(\.title)
        return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }

    /// The group's material: Set, Sheet, Checks (Placement when each member is placed), Worked example, Figure.
    private func marks(_ plan: PlanRecord, group: PlanGroup) -> [ReadyMark] {
        let items = plan.items.filter { $0.groupNo == group.number }
        let placed = items.filter { $0.kind == .check && $0.studentID != nil }
            .allSatisfy { $0.words.hasPrefix("Placement") }
        var marks: [(String, Artefact?)] = [
            ("Set", plan.artefact(group: group.number, kind: .sheet, homework: false)),
            ("Sheet", plan.artefact(group: group.number, kind: .sheet, homework: true)),
            (placed ? "Placement" : "Checks", checksMark(plan, items: items, group: group.number)),
            ("Worked example", plan.artefact(group: group.number, kind: .workedExample)),
        ]
        if items.contains(where: { $0.kind == .figure }) {
            marks.append(("Figure", plan.artefact(group: group.number, kind: .figure)))
        }
        return marks.map { name, artefact in
            ReadyMark(name: name, state: artefact != nil ? .made : planning ? .onItsWay : .notMade)
        }
    }

    /// The group's checks, or a member's own when every member has their own.
    private func checksMark(_ plan: PlanRecord, items: [PlanItem], group: Int) -> Artefact? {
        if let shared = plan.artefact(group: group, kind: .check) {
            return shared
        }
        let members = items.filter { $0.kind == .check }.compactMap(\.studentID)
        let own = members.compactMap { plan.checks(for: $0) }
        return !members.isEmpty && own.count == members.count ? own.first : nil
    }

    private func studentLines(_ plan: PlanRecord, group: Int) -> [PlanLineModel] {
        let students = Set(plan.items.filter { $0.groupNo == group }.compactMap(\.studentID))
        return students.compactMap { id -> PlanLineModel? in
            let items = plan.items(of: id)
            guard !items.isEmpty, !items.allSatisfy({ $0.skippedAt != nil }) else { return nil }
            let student = register.student(id)
            let name = student?.name ?? ""
            let status = student?.trackStatus ?? .notKnown
            let teach = items.first { $0.kind == .catchUp }?.words ?? items.first { $0.kind == .teach }?.words ?? ""
            let rest = items.filter { [.practise, .check, .homework].contains($0.kind) }.map {
                LineBit(text: $0.words, struck: $0.skippedAt != nil)
            }
            return PlanLineModel(
                id: id, initials: NameInitials.of(name), name: name, status: status.title,
                statusKind: Self.kind(status), note: note(items), teach: teach, rest: rest, items: items,
                groupNo: group
            )
        }
        .sorted { $0.name < $1.name }
    }

    /// "Moved here from Group 2", else what was skipped today.
    private func note(_ items: [PlanItem]) -> PlanLineNote? {
        if let from = items.compactMap(\.movedFrom).first {
            return .movedFrom(from)
        }
        let check = items.contains { $0.kind == .check && $0.skippedAt != nil }
        let homework = items.contains { $0.kind == .homework && $0.skippedAt != nil }
        return switch (check, homework) {
        case (true, true): .skipped("Check and homework skipped today")
        case (true, false): .skipped("Check skipped today")
        case (false, true): .skipped("Homework skipped today")
        case (false, false): nil
        }
    }

    static func kind(_ status: TrackStatus) -> TrackKind {
        switch status {
        case .onTrack: .onTrack
        case .watch: .watch
        case .notOnTrack: .notOnTrack
        case .notKnown: .notKnown
        }
    }
}
