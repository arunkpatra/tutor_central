import Data
import Foundation

/// What a share left in the inbox, as AppShell hands it to School: the inbox's id (removed once its items are added or
/// the screen is left), the text, or the photo already reduced.
public struct SharedRead: Hashable, Sendable {
    public let id: String
    public let text: String?
    public let image: ImageUpload?
    public let receivedAt: Date

    public init(id: String, text: String?, image: ImageUpload?, receivedAt: Date) {
        self.id = id
        self.text = text
        self.image = image
        self.receivedAt = receivedAt
    }
}

/// Where "Check what was read" starts (plan/phase-13-plan.md decisions 1 and 5): a photo from the "+" menu, a pasted
/// message, a share, or nothing read (Add by hand).
public enum ReadSource: Hashable, Sendable {
    case photo(ImageUpload)
    case pasted(String)
    case typed
    case shared(SharedRead)
    /// Paste a message (U41): the screen waits for the system's Paste button, so iOS asks nothing.
    case pasteWaiting
}

/// The School tab's pushes and sheets. AppShell owns the stack; the feature asks for a screen.
public struct SchoolActions: Sendable {
    public let openItem: @MainActor (UUID) -> Void
    public let read: @MainActor (ReadSource) -> Void
    public let askParents: @MainActor () -> Void

    public init(
        openItem: @escaping @MainActor (UUID) -> Void, read: @escaping @MainActor (ReadSource) -> Void,
        askParents: @escaping @MainActor () -> Void
    ) {
        self.openItem = openItem
        self.read = read
        self.askParents = askParents
    }
}
