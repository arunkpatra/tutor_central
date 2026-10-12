import Data
import Domain
import Foundation

/// An artefact and the plan it belongs to: read, else, offline, from the plan's copy on this iPhone, so the material
/// opens in the room as Today's plan does (D39).
enum ArtefactRead {
    typealias Found = (artefact: Artefact, plan: PlanRecord?)

    /// The plan's copy on this iPhone: an artefact's kind never changes, so a screen opens on it at once.
    static func copy(_ id: UUID, cache: PlanCache?) -> Found? {
        cache?.artefact(id).map { ($0.artefact, $0.plan) }
    }

    /// `copy` takes the plan's copy before the read: offline a read takes its timeout to fail, and the screen stood
    /// blank until then (Phase 18's hand run 8).
    static func read(
        _ id: UUID, centre: UUID, plans: any PlansRepository, cache: PlanCache?,
        copy shown: (@MainActor (Found) -> Void)? = nil
    ) async throws -> Found? {
        if let shown, let found = copy(id, cache: cache) {
            await shown(found)
        }
        do {
            guard let found = try await plans.artefact(id: id, centre: centre) else { return nil }
            let plan = try await found.planID.asyncMap { try await plans.plan(id: $0, centre: centre) } ?? nil
            return (found, plan)
        } catch {
            guard TransportError.isOffline(error), let copy = cache?.artefact(id) else { throw error }
            return (copy.artefact, copy.plan)
        }
    }
}

private extension Optional {
    func asyncMap<T>(_ transform: (Wrapped) async throws -> T) async rethrows -> T? {
        guard let self else { return nil }
        return try await transform(self)
    }
}
