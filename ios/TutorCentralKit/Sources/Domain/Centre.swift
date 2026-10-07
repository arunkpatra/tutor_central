import Foundation

/// A tuition centre: the tutor's own, created at onboarding.
public struct Centre: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    /// E.164 (+919611299988) or nil.
    public var whatsappNumber: String?

    public init(id: UUID, name: String, whatsappNumber: String?) {
        self.id = id
        self.name = name
        self.whatsappNumber = whatsappNumber
    }
}
