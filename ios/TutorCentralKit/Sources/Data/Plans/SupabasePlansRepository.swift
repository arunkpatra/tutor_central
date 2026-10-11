import Domain
import Foundation
import Supabase

public final class SupabasePlansRepository: PlansRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    /// The embeds name their foreign keys: `artefacts` also reaches `plans` through `plan_items`.
    private static let columns = "id, class_id, date, made_at, session_id, groups, "
        + "plan_items!plan_items_centre_id_plan_id_fkey(id, student_id, group_no, kind, skill_id, words, artefact_id, "
        + "done_at, skipped_at, moved_from), artefacts!artefacts_centre_id_plan_id_fkey(\(ArtefactRow.columns))"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func plan(centre: UUID, classID: UUID, date: Day) async throws -> PlanRecord? {
        let response = try await client.from("plans").select(Self.columns).eq("centre_id", value: centre)
            .eq("class_id", value: classID).eq("date", value: date.iso).limit(1).execute()
        return try await withShared(Self.decoder.decode([PlanRow].self, from: response.data).first?.record, centre)
    }

    public func plan(id: UUID, centre: UUID) async throws -> PlanRecord? {
        let response = try await client.from("plans").select(Self.columns).eq("centre_id", value: centre)
            .eq("id", value: id).limit(1).execute()
        return try await withShared(Self.decoder.decode([PlanRow].self, from: response.data).first?.record, centre)
    }

    /// The artefacts the plan's lines link that another plan kept (an exam's mock shared by two batches): the embed
    /// reaches only those whose `plan_id` is this plan.
    private func withShared(_ plan: PlanRecord?, _ centre: UUID) async throws -> PlanRecord? {
        guard var plan else { return nil }
        let missing = Set(plan.items.compactMap(\.artefactID)).subtracting(plan.artefacts.map(\.id))
        guard !missing.isEmpty else { return plan }
        let response = try await client.from("artefacts").select(ArtefactRow.columns).eq("centre_id", value: centre)
            .in("id", values: missing.map { $0.uuidString.lowercased() }).execute()
        plan.artefacts += try Self.decoder.decode([ArtefactRow].self, from: response.data).compactMap(\.artefact)
        return plan
    }

    public func make(_ draft: PlanDraft, centre: UUID) async throws -> PlanRecord {
        let response = try await client.rpc("make_plan", params: Self.makeParams(draft, centre: centre)).execute()
        let made = try Self.decoder.decode(MadePlanRow.self, from: response.data)
        return Self.record(made, draft: draft, at: Date())
    }

    public func keep(_ artefact: NewArtefact, to link: ArtefactLink, centre: UUID) async throws -> Artefact {
        let params = try Self.keepParams(artefact, to: link, centre: centre)
        let response = try await client.rpc("keep_artefact", params: params).execute()
        let id = try Self.decoder.decode(UUID.self, from: response.data)
        guard let kept = try await self.artefact(id: id, centre: centre) else { throw URLError(.cannotParseResponse) }
        return kept
    }

    public func artefact(id: UUID, centre: UUID) async throws -> Artefact? {
        let response = try await client.from("artefacts").select(ArtefactRow.columns).eq("centre_id", value: centre)
            .eq("id", value: id).limit(1).execute()
        return try Self.decoder.decode([ArtefactRow].self, from: response.data).first?.artefact
    }

    public func mock(for item: UUID, centre: UUID) async throws -> Artefact? {
        try await artefacts(for: item, centre: centre).first { $0.kind == .mock }
    }

    public func gapReport(for item: UUID, student: UUID, centre: UUID) async throws -> Artefact? {
        try await artefacts(for: item, centre: centre).first { $0.kind == .gapReport && $0.studentID == student }
    }

    public func artefacts(for item: UUID, centre: UUID) async throws -> [Artefact] {
        let response = try await client.from("artefacts").select(ArtefactRow.columns).eq("centre_id", value: centre)
            .eq("school_item_id", value: item).order("created_at", ascending: false).execute()
        return try Self.decoder.decode([ArtefactRow].self, from: response.data).compactMap(\.artefact)
    }

    public func notes(centre: UUID, students: [UUID], since: Date) async throws -> [Artefact] {
        guard !students.isEmpty else { return [] }
        let response = try await client.from("artefacts").select(ArtefactRow.columns).eq("centre_id", value: centre)
            .in("kind", values: [ArtefactKind.note.rawValue, ArtefactKind.canDo.rawValue])
            .in("student_id", values: students.map(\.uuidString))
            .gte("created_at", value: ISO8601DateFormatter().string(from: since))
            .order("created_at", ascending: false).execute()
        return try Self.decoder.decode([ArtefactRow].self, from: response.data).compactMap(\.artefact)
    }

    public func setContent(_ content: ArtefactContent, artefact: UUID, centre: UUID) async throws {
        let json = try JSONDecoder().decode(AnyJSON.self, from: content.encoded())
        try await client.from("artefacts").update(["content": json]).eq("centre_id", value: centre)
            .eq("id", value: artefact).execute()
    }

    public func nameGroup(plan: UUID, group: Int, chapter: String, skill: String, centre: UUID) async throws {
        let params: [String: AnyJSON] = [
            "p_centre": Self.id(centre), "p_plan": Self.id(plan), "p_group_no": .integer(group),
            "p_chapter": .string(chapter), "p_skill": .string(skill),
        ]
        try await client.rpc("name_plan_group", params: params).execute()
    }

    public func briefChapters(centre: UUID) async throws -> Set<String> {
        let response = try await client.from("artefacts").select("title").eq("centre_id", value: centre)
            .eq("kind", value: ArtefactKind.brief.rawValue).execute()
        let rows = try Self.decoder.decode([TitleRow].self, from: response.data)
        return Set(rows.map { Self.chapter(ofBrief: $0.title) })
    }

    public func skip(item: UUID, centre: UUID) async throws {
        try await client.from("plan_items").update(["skipped_at": AnyJSON.string(Self.now())])
            .eq("centre_id", value: centre).eq("id", value: item).execute()
    }

    public func move(items: [UUID], to group: Int, from: Int, centre: UUID) async throws {
        guard !items.isEmpty else { return }
        try await client.from("plan_items")
            .update(["group_no": AnyJSON.integer(group), "moved_from": AnyJSON.integer(from)])
            .eq("centre_id", value: centre).in("id", values: items.map { $0.uuidString.lowercased() }).execute()
    }

    public func leaveOut(student: UUID, plan: UUID, centre: UUID) async throws {
        try await client.from("plan_items").update(["skipped_at": AnyJSON.string(Self.now())])
            .eq("centre_id", value: centre).eq("plan_id", value: plan).eq("student_id", value: student).execute()
    }

    public func link(items: [UUID], to artefact: UUID?, centre: UUID) async throws {
        guard !items.isEmpty else { return }
        try await client.from("plan_items")
            .update(["artefact_id": artefact.map { AnyJSON.string($0.uuidString.lowercased()) } ?? .null])
            .eq("centre_id", value: centre).in("id", values: items.map { $0.uuidString.lowercased() }).execute()
    }

    // MARK: - Params

    /// `make_plan(p_centre, p_class, p_date, p_groups, p_subjects, p_items)`: the groups as the cards read them, the
    /// subject per group number, one item per line.
    static func makeParams(_ draft: PlanDraft, centre: UUID) -> [String: AnyJSON] {
        let groups = (try? AnyJSON.encoding(draft.groups)) ?? .array([])
        let subjects = Dictionary(uniqueKeysWithValues: draft.groups.map { (
            String($0.number),
            AnyJSON.string($0.subject)
        ) })
        let items: [AnyJSON] = draft.lines.map { line in
            var item: [String: AnyJSON] = [
                "group_no": .integer(line.groupNo),
                "kind": .string(line.kind.rawValue),
                "words": .string(line.words),
            ]
            if let student = line.studentID {
                item["student_id"] = id(student)
            }
            if let skill = line.skillID {
                item["skill_id"] = id(skill)
            }
            return .object(item)
        }
        return [
            "p_centre": id(centre),
            "p_class": id(draft.classID),
            "p_date": .string(draft.date.iso),
            "p_groups": groups,
            "p_subjects": .object(subjects),
            "p_items": .array(items),
        ]
    }

    /// `keep_artefact(p_centre, p_artefact, p_plan, p_group_no, p_student, p_item_kind, p_school_item)`: the content in
    /// snake-case keys, no student for the group's material; an exam's artefact with no plan links no line.
    static func keepParams(_ artefact: NewArtefact, to link: ArtefactLink, centre: UUID) throws -> [String: AnyJSON] {
        let content = try JSONDecoder().decode(AnyJSON.self, from: artefact.content.encoded())
        var row: [String: AnyJSON] = [
            "kind": .string(artefact.kind.rawValue),
            "source": .string(artefact.source.rawValue),
            "title": .string(artefact.title),
            "content": content,
        ]
        if let path = artefact.photoPath {
            row["photo_path"] = .string(path)
        }
        if let generation = artefact.generationID {
            row["generation_id"] = id(generation)
        }
        if let old = artefact.regeneratedFrom {
            row["regenerated_from"] = id(old)
        }
        return [
            "p_centre": id(centre),
            "p_artefact": .object(row),
            "p_plan": link.plan.map(id) ?? .null,
            "p_group_no": .integer(link.group),
            "p_student": link.student.map(id) ?? .null,
            "p_item_kind": .string(link.itemKind.rawValue),
            "p_school_item": link.schoolItem.map(id) ?? .null,
        ]
    }

    /// The written plan as a record: the draft's groups, the answer's ids matched to the draft's lines by student,
    /// group and kind (one line each).
    static func record(_ made: MadePlanRow, draft: PlanDraft, at now: Date) -> PlanRecord {
        let items = made.items.map { item in
            let line = draft.lines
                .first { $0.studentID == item.studentId && $0.groupNo == item.groupNo && $0.kind == item.kind }
            return PlanItem(
                id: item.id, studentID: item.studentId, groupNo: item.groupNo, kind: item.kind, skillID: line?.skillID,
                words: line?.words ?? "", artefactID: nil, doneAt: nil, skippedAt: nil, movedFrom: nil
            )
        }
        let order = { (item: PlanItem) in
            draft.lines
                .firstIndex { $0.studentID == item.studentID && $0.groupNo == item.groupNo && $0.kind == item.kind }
                ?? Int.max
        }
        return PlanRecord(
            id: made.planId, classID: draft.classID, date: draft.date, madeAt: now, groups: draft.groups,
            items: items.sorted { order($0) < order($1) }, artefacts: [], sessionID: nil
        )
    }

    /// "Your brief · Chemical reactions" names "Chemical reactions".
    static func chapter(ofBrief title: String) -> String {
        title.hasPrefix(PlanRules.briefPrefix) ? String(title.dropFirst(PlanRules.briefPrefix.count)) : title
    }

    private static func id(_ uuid: UUID) -> AnyJSON {
        .string(uuid.uuidString.lowercased())
    }

    private static func now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private struct TitleRow: Decodable {
        let title: String
    }
}
