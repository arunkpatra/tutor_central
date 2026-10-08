import Domain
import Foundation

/// Where the AI Assistant's screens lead, given by AppShell: features never import each other (rule 4).
public struct AIToolsActions {
    public let openStudent: (UUID) -> Void
    public let openResult: (UUID) -> Void
    public let openForm: (GenerationKind) -> Void
    public let openHistory: () -> Void

    public init(
        openStudent: @escaping (UUID) -> Void, openResult: @escaping (UUID) -> Void,
        openForm: @escaping (GenerationKind) -> Void, openHistory: @escaping () -> Void
    ) {
        self.openStudent = openStudent
        self.openResult = openResult
        self.openForm = openForm
        self.openHistory = openHistory
    }
}
