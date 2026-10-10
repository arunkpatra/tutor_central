import Domain
import Foundation
import Supabase

/// A `plans` row with its `plan_items` and `artefacts` embedded (PostgREST, snake_case keys converted).
struct PlanRow: Decodable {
    let id: UUID
    let classId: UUID?
    let date: String
    let madeAt: Date
    let sessionId: UUID?
    let groups: [PlanGroup]
    let planItems: [PlanItemRow]
    let artefacts: [ArtefactRow]

    var record: PlanRecord {
        PlanRecord(
            id: id, classID: classId ?? id, date: Day(iso: date) ?? Day(madeAt, calendar: DayHeading.india),
            madeAt: madeAt, groups: groups, items: planItems.map(\.item), artefacts: artefacts.compactMap(\.artefact),
            sessionID: sessionId
        ).keepingLinkedArtefacts()
    }
}

struct PlanItemRow: Decodable {
    let id: UUID
    let studentId: UUID?
    let groupNo: Int?
    let kind: PlanLineKind
    let skillId: UUID?
    let words: String
    let artefactId: UUID?
    let doneAt: Date?
    let skippedAt: Date?
    let movedFrom: Int?

    var item: PlanItem {
        PlanItem(
            id: id, studentID: studentId, groupNo: groupNo ?? 1, kind: kind, skillID: skillId, words: words,
            artefactID: artefactId, doneAt: doneAt, skippedAt: skippedAt, movedFrom: movedFrom
        )
    }
}

/// An `artefacts` row. Its `content` is read as JSON and decoded by the kind; a kind this build does not know is left
/// out of the plan.
struct ArtefactRow: Decodable {
    let id: UUID
    let kind: String
    let source: String
    let title: String
    let content: AnyJSON
    let photoPath: String?
    let studentId: UUID?
    let planId: UUID?
    let regeneratedFrom: UUID?
    let createdAt: Date

    static let columns =
        "id, kind, source, title, content, photo_path, student_id, plan_id, regenerated_from, created_at"

    var artefact: Artefact? {
        guard let kind = ArtefactKind(rawValue: kind) else { return nil }
        let source = ArtefactSource(rawValue: source) ?? .made
        let json = (try? JSONEncoder().encode(content)) ?? Data("{}".utf8)
        let decoded = (try? ArtefactContent.decode(kind: kind, json: json, source: source)) ?? .other
        return Artefact(
            id: id, kind: kind, source: source, title: title, content: decoded, photoPath: photoPath,
            studentID: studentId, planID: planId, regeneratedFrom: regeneratedFrom, madeAt: createdAt
        )
    }
}

/// `make_plan`'s answer: the plan's id and each written item's id, student, group and kind.
struct MadePlanRow: Decodable {
    struct Item: Decodable {
        let id: UUID
        let studentId: UUID?
        let groupNo: Int
        let kind: PlanLineKind
    }

    let planId: UUID
    let items: [Item]
}

extension AnyJSON {
    /// An `Encodable` value as the JSON `rpc` sends.
    static func encoding(_ value: some Encodable, snakeCase: Bool = false) throws -> AnyJSON {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if snakeCase {
            encoder.keyEncodingStrategy = .convertToSnakeCase
        }
        return try JSONDecoder().decode(AnyJSON.self, from: encoder.encode(value))
    }
}
