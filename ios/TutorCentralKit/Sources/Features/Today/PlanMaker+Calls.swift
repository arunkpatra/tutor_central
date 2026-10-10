import Data
import Domain
import Foundation

/// Where an artefact goes before the plan's id is known: the group's lines of a kind, or one student's.
struct LinePlace: Sendable {
    let group: Int
    let student: UUID?
    let kind: PlanLineKind

    func on(_ plan: UUID) -> ArtefactLink {
        ArtefactLink(plan: plan, group: group, student: student, itemKind: kind)
    }
}

extension PlanMaker {
    /// One request of the budget made and shaped as the artefact to keep; nil when the call fails (the rest goes on),
    /// or when a figure's spec fails the app's own rule (D59).
    func made(_ request: ArtefactRequest, work: PlanWork) async -> (NewArtefact, LinePlace)? {
        let place = place(of: request, in: work.draft)
        do {
            switch request {
            case let .checks(_, skills, ids, level, subject), let .personalChecks(_, skills, ids, level, subject):
                let made = try await ai.makeChecksWithID(
                    classLevel: level, subject: subject, skills: skills, centre: work.centre
                )
                let content = Self.checks(made.questions, ids: ids, placement: false)
                return (artefact(.check, "Checks · \(skills.first ?? "")", content, made.generationID), place)
            case let .placement(student, level):
                return try await placement(student, level: level, work: work).map { ($0, place) }
            case .sheet, .workedExample, .figure, .brief:
                return try await groupMaterial(request, centre: work.centre).map { ($0, place) }
            }
        } catch {
            return nil
        }
    }

    /// The set, the sheet, the worked example, the figure, the brief.
    private func groupMaterial(_ request: ArtefactRequest, centre: UUID) async throws -> NewArtefact? {
        switch request {
        case let .sheet(_, skills, level, subject, questions, forHomework):
            let asked = SheetRequest(
                classLevel: level, subject: subject, skills: skills, questions: questions, forHomework: forHomework
            )
            let made = try await ai.makeSheet(asked, centre: centre)
            let title = "\(skills.first ?? made.content.title) · \(forHomework ? "sheet" : "set") 1"
            return artefact(.sheet, title, .sheet(made.content), made.generationID)
        case let .workedExample(_, skill, level, subject):
            let made = try await ai.makeWorkedExample(classLevel: level, subject: subject, skill: skill, centre: centre)
            return artefact(.workedExample, skill, .workedExample(made.example), made.generationID)
        case let .figure(_, kind, skill, level, subject):
            let made = try await ai.makeFigure(kind, classLevel: level, subject: subject, skill: skill, centre: centre)
            guard made.figure.figure.kind == kind, made.figure.figure.validate() == nil else { return nil }
            return artefact(.figure, skill, .figure(made.figure), made.generationID)
        case let .brief(_, chapter, level, subject):
            let made = try await ai.makeBrief(classLevel: level, subject: subject, chapter: chapter, centre: centre)
            return artefact(.brief, PlanRules.briefPrefix + chapter, .brief(made.brief), made.generationID)
        case .checks, .personalChecks, .placement:
            return nil
        }
    }

    /// The placement's questions per subject in `Placement.groups` order, kept as one artefact of kind placement.
    private func placement(_ student: UUID, level: ClassLevel, work: PlanWork) async throws -> NewArtefact? {
        let record = work.record
        let groups = Placement.groups(chapters: record.chapters[student] ?? [], skills: record.skills[student] ?? [])
        var questions: [CheckContent.Question] = []
        for group in groups {
            let made = try await ai.makePlacement(
                classLevel: level, subject: group.title, chapters: group.items.map(\.name), centre: work.centre
            )
            questions += zip(group.items, made).map { item, made in
                CheckContent.Question(
                    skillID: item.skillID, skill: item.skill, question: made.question, answer: made.answer
                )
            }
        }
        guard !questions.isEmpty else { return nil }
        return artefact(.placement, "Placement", .check(CheckContent(questions: questions, placement: true)), nil)
    }

    private func artefact(_ kind: ArtefactKind, _ title: String, _ content: ArtefactContent, _ generation: UUID?)
        -> NewArtefact {
        NewArtefact(
            kind: kind, source: .made, title: title, content: content, photoPath: nil, generationID: generation,
            regeneratedFrom: nil
        )
    }

    /// Where a request's artefact goes.
    func place(of request: ArtefactRequest, in draft: PlanDraft) -> LinePlace {
        switch request {
        case let .checks(group, _, _, _, _): LinePlace(group: group, student: nil, kind: .check)
        case let .personalChecks(student, _, _, _, _), let .placement(student, _):
            LinePlace(group: groupOf(student, draft), student: student, kind: .check)
        case let .sheet(group, _, _, _, _, forHomework):
            LinePlace(group: group, student: nil, kind: forHomework ? .homework : .practise)
        case let .workedExample(group, _, _, _): LinePlace(group: group, student: nil, kind: .workedExample)
        case let .figure(group, _, _, _, _): LinePlace(group: group, student: nil, kind: .figure)
        case let .brief(group, _, _, _): LinePlace(group: group, student: nil, kind: .brief)
        }
    }

    private func groupOf(_ student: UUID, _ draft: PlanDraft) -> Int {
        draft.groups.first { $0.memberIDs.contains(student) }?.number ?? 1
    }

    /// The checks' questions with their skill rows; a skill /ai/plan named has no row yet and takes a fresh id (the
    /// close matches the group's questions to each student's skills by name).
    static func checks(_ questions: [CheckQuestion], ids: [UUID], placement: Bool) -> ArtefactContent {
        let rows = questions.enumerated().map { index, made in
            CheckContent.Question(
                skillID: index < ids.count ? ids[index] : UUID(), skill: made.skill, question: made.question,
                answer: made.answer
            )
        }
        return .check(CheckContent(questions: rows, placement: placement))
    }
}

extension PlanRecord {
    /// An artefact another copy of this plan kept, linked here as the database linked it: one student's lines of
    /// its kind, or the lines of its kind in the group as each line stands now.
    func merging(_ artefact: Artefact, from other: PlanRecord) -> PlanRecord {
        var record = self
        if !record.artefacts.contains(where: { $0.id == artefact.id }) {
            record.artefacts.append(artefact)
        }
        let places = other.items.filter { $0.artefactID == artefact.id }
        for place in places {
            for index in record.items.indices where record.items[index].kind == place.kind {
                let item = record.items[index]
                let matches = artefact.studentID.map { item.studentID == $0 }
                    ?? (place.studentID == nil ? item.groupNo == place.groupNo && item.studentID == nil
                        : item.groupNo == place.groupNo)
                if matches {
                    record.items[index].artefactID = artefact.id
                }
            }
        }
        let linked = Set(record.items.compactMap(\.artefactID))
        record.artefacts = record.artefacts.filter { linked.contains($0.id) }
        return record
    }

    /// The plan as a draft again (the rules' lines from its items), for the budget of what it still misses. A check
    /// line is personal where the rules made it so: a placement, a teach again, a catch-up.
    var asDraft: PlanDraft {
        let lines = items.map { item in
            let theirs = item.studentID.map { items(of: $0) } ?? []
            let personal = item.kind == .check && (item.words.hasPrefix("Placement")
                || theirs.contains { $0.kind == .catchUp }
                || theirs.contains { $0.kind == .teach && $0.words.hasPrefix("Teach again") })
            return PlanLine(
                studentID: item.studentID, groupNo: item.groupNo, kind: item.kind, skillID: item.skillID,
                words: item.words, personalChecks: personal
            )
        }
        return PlanDraft(classID: classID, date: date, groups: groups, lines: lines, leftOut: [])
    }

    /// Whether the plan already holds the artefact for a place.
    func fills(_ place: LinePlace) -> Bool {
        if let student = place.student {
            return artefacts.contains { $0.studentID == student && [.check, .placement].contains($0.kind) }
        }
        return switch place.kind {
        case .practise: artefact(group: place.group, kind: .sheet, homework: false) != nil
        case .homework: artefact(group: place.group, kind: .sheet, homework: true) != nil
        case .check: artefact(group: place.group, kind: .check) != nil || eachHasOwnChecks(place.group)
        default: items.contains { $0.kind == place.kind && $0.groupNo == place.group && $0.artefactID != nil }
        }
    }

    /// Whether the plan has the line a place's artefact links to (a figure only where the rules wrote its line).
    func hasLine(for place: LinePlace) -> Bool {
        items.contains { item in
            item.kind == place.kind && item.groupNo == place.group
                && (place.student.map { item.studentID == $0 } ?? true)
        }
    }

    /// Every member's check line in the group links their own checks.
    private func eachHasOwnChecks(_ group: Int) -> Bool {
        let lines = items.filter { $0.groupNo == group && $0.kind == .check && $0.studentID != nil }
        return !lines.isEmpty && lines.allSatisfy { line in
            artefact(line.artefactID).map { $0.studentID == line.studentID } ?? false
        }
    }

    /// The record with an artefact kept and linked as the database linked it.
    func keeping(_ artefact: Artefact, link: LinePlace) -> PlanRecord {
        var record = self
        record.artefacts.append(artefact)
        for index in record.items.indices where record.items[index].kind == link.kind {
            let item = record.items[index]
            if link.student.map({ item.studentID == $0 }) ?? (item.groupNo == link.group) {
                record.items[index].artefactID = artefact.id
            }
        }
        let linked = Set(record.items.compactMap(\.artefactID))
        record.artefacts = record.artefacts.filter { linked.contains($0.id) }
        return record
    }
}
