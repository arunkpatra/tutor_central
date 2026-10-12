import Foundation

/// How a copy-first read ended: the network's list shown and kept, a failure with the copy still shown, or a failure
/// with nothing saved to show (the unavailable view).
public enum CopyFirstOutcome: Sendable {
    case fresh
    case keptCopy(any Error)
    case nothing(any Error)

    /// The read failed, whatever is shown.
    public var failure: (any Error)? {
        switch self {
        case .fresh: nil
        case let .keptCopy(error), let .nothing(error): error
        }
    }
}

/// The one way a list reads (D76, plan/phase-18-plan.md decision 19): the copy on this iPhone shown at once with the
/// time it was saved, then the read; a good read is shown and kept, a failed one keeps what is shown. A store's own
/// rule for stale answers stays around it (`show` drops what it no longer wants).
public struct CopyFirst<Value: Codable & Sendable>: Sendable {
    private let copy: @Sendable () -> CachedValue<Value>?
    private let keep: @Sendable (Value, Date) -> Void
    private let now: @Sendable () -> Date

    public init(cache: CachedRead<Value>?, now: @escaping @Sendable () -> Date) {
        copy = { cache?.load() }
        keep = { value, at in cache?.keep(value, at: at) }
        self.now = now
    }

    /// `showingCopy` false skips the copy (the list on screen is already newer); `show` gets the value and when it
    /// was read: the copy's save, or now.
    public func load(
        showingCopy: Bool = true, show: @MainActor (Value, Date) -> Void,
        read: @Sendable () async throws -> Value
    ) async -> CopyFirstOutcome {
        let saved = showingCopy ? copy() : nil
        if let saved {
            await show(saved.value, saved.savedAt)
        }
        do {
            let value = try await read()
            let at = now()
            keep(value, at)
            await show(value, at)
            return .fresh
        } catch {
            return saved == nil ? .nothing(error) : .keptCopy(error)
        }
    }
}
