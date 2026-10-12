import Domain
import Foundation
import Supabase

/// `jobs` read and asked for through the signed-in user (RLS: the centre's rows; the requests check the membership).
public struct SupabaseJobsRepository: JobsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    struct Row: Decodable {
        let id: UUID
        let state: JobStatus.State
        let createdAt: Date
        let finishedAt: Date?
        let result: JobResult?

        var status: JobStatus {
            JobStatus(id: id, state: state, createdAt: createdAt, finishedAt: finishedAt, reason: result?.reason)
        }
    }

    /// The part of a job's result the app reads.
    struct JobResult: Decodable {
        let reason: String?
    }

    public func planJob(centre: UUID, classID: UUID, date: Day) async throws -> JobStatus? {
        let response = try await client.from("jobs").select("id, state, created_at, finished_at, result")
            .eq("centre_id", value: centre.uuidString).eq("kind", value: "plan")
            .eq("input->>class_id", value: classID.uuidString.lowercased()).eq("input->>date", value: date.iso)
            .order("created_at", ascending: false).limit(1).execute()
        return try PostgRESTDecoder.make().decode([Row].self, from: response.data).first?.status
    }

    public func requestPlan(centre: UUID, classID: UUID, date: Day, choices: PlanChoices?) async throws -> UUID {
        let response = try await client.rpc("request_plan", params: Self.planParams(
            centre: centre, classID: classID, date: date, choices: choices
        )).execute()
        return try PostgRESTDecoder.make().decode(UUID.self, from: response.data)
    }

    public func cancel(centre: UUID, job: UUID) async throws {
        try await client.rpc("cancel_job", params: [
            "p_centre": AnyJSON.string(centre.uuidString), "p_job": .string(job.uuidString),
        ]).execute()
    }

    /// The choices as the plan job reads them: `{ groups, subjects: { "1": "Mathematics" } }`.
    static func planParams(centre: UUID, classID: UUID, date: Day, choices: PlanChoices?) -> [String: AnyJSON] {
        var params: [String: AnyJSON] = [
            "p_centre": .string(centre.uuidString), "p_class": .string(classID.uuidString), "p_date": .string(date.iso),
            "p_choices": .null,
        ]
        if let choices {
            var object: [String: AnyJSON] = [
                "subjects": .object(Dictionary(uniqueKeysWithValues: choices.subjects.map {
                    (String($0.key), AnyJSON.string($0.value))
                })),
            ]
            if let groups = choices.groups {
                object["groups"] = .integer(groups)
            }
            params["p_choices"] = .object(object)
        }
        return params
    }
}
