import Domain
import Foundation

/// Where Make's screens lead, given by AppShell: features never import each other (rule 4).
public struct MakeActions {
    public let openStudent: (UUID) -> Void
    /// A V1 result (a paper, homework, worksheet or progress note).
    public let openResult: (UUID) -> Void
    /// A Make artefact's screen (the Artefacts feature's, by AppShell's route).
    public let openArtefact: (UUID) -> Void
    /// A kind's form: V1's for the three V1 kinds, Make's for the others.
    public let openForm: (MakeKind) -> Void
    public let openHistory: () -> Void

    public init(
        openStudent: @escaping (UUID) -> Void, openResult: @escaping (UUID) -> Void,
        openArtefact: @escaping (UUID) -> Void, openForm: @escaping (MakeKind) -> Void,
        openHistory: @escaping () -> Void
    ) {
        self.openStudent = openStudent
        self.openResult = openResult
        self.openArtefact = openArtefact
        self.openForm = openForm
        self.openHistory = openHistory
    }

    func open(_ opens: MakeStore.Opens) {
        switch opens {
        case let .artefact(id): openArtefact(id)
        case let .generation(id): openResult(id)
        }
    }
}
