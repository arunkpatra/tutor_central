import Data
import Domain
import Foundation

/// An artefact and the plan it belongs to: read, else, offline, from the plan's copy on this iPhone, so the material
/// opens in the room as Today's plan does (D39).
enum ArtefactRead {
    static func read(
        _ id: UUID, centre: UUID, plans: any PlansRepository, cache: PlanCache?
    ) async throws -> (artefact: Artefact, plan: PlanRecord?)? {
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
