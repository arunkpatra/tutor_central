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

    public func made(centre: UUID) async throws -> [Artefact] {
        let response = try await client.from("artefacts").select(ArtefactRow.columns).eq("centre_id", value: centre)
            .eq("made_from", value: "make").order("created_at", ascending: false).limit(50).execute()
        return try Self.decoder.decode([ArtefactRow].self, from: response.data).compactMap(\.artefact)
            .hidingRegenerated()
    }

    public func setContent(_ content: ArtefactContent, artefact: UUID, centre: UUID) async throws {
        let json = try JSONDecoder().decode(AnyJSON.self, from: content.encoded())
        try await client.from("artefacts").update(["content": json]).eq("centre_id", value: centre)
            .eq("id", value: artefact).execute()
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

    /// `keep_artefact(p_centre, p_artefact, p_plan, p_group_no, p_student, p_item_kind, p_school_item)`: the content in
    /// snake-case keys, no student for the group's material; an exam's artefact with no plan links no line.
    static func keepParams(_ artefact: NewArtefact, to link: ArtefactLink, centre: UUID) throws -> [String: AnyJSON] {
        let content = try JSONDecoder().decode(AnyJSON.self, from: artefact.content.encoded(madeFor: artefact.madeFor))
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
        var params: [String: AnyJSON] = [
            "p_centre": id(centre),
            "p_artefact": .object(row),
            "p_plan": link.plan.map(id) ?? .null,
            "p_group_no": .integer(link.group),
            "p_student": link.student.map(id) ?? .null,
            "p_item_kind": .string(link.itemKind.rawValue),
            "p_school_item": link.schoolItem.map(id) ?? .null,
        ]
        // The plan's keeps send seven arguments, as before 0026.
        if artefact.madeFor != nil {
            params["p_made_from"] = .string("make")
        }
        // A made artefact is kept once (0033): a keep replayed answers the first row. The key is the generation and
        // what it replaces, so the made sheet kept again over the tutor's own is a row of its own. An own one has none.
        if let generation = artefact.generationID {
            let key = [generation, artefact.regeneratedFrom].compactMap { $0?.uuidString.lowercased() }
            params["p_key"] = .string(key.joined(separator: ":"))
        }
        return params
    }

    private static func id(_ uuid: UUID) -> AnyJSON {
        .string(uuid.uuidString.lowercased())
    }

    private static func now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
