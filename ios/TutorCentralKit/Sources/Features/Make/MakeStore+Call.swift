import Data
import Domain
import Foundation

/// Make's one call (decision 13): it belongs to the store, so leaving the form does not lose it; when it lands the
/// artefact joins Recent and AppShell is told.
public extension MakeStore {
    struct Running: Hashable, Sendable {
        public let kind: MakeKind
        /// "Making the sheet".
        public let title: String
    }

    struct Failure: Hashable, Sendable {
        public let kind: MakeKind
        public let message: String
        public let canRetry: Bool
    }

    /// Stops waiting; a late answer is dropped (the call is still counted, the safe side).
    func cancel() {
        task?.cancel()
        task = nil
        running = nil
    }

    /// Clears a kind's failure (a new attempt, or the form changed).
    func clearFailure(_ kind: MakeKind) {
        if failure?.kind == kind {
            failure = nil
        }
    }
}

extension MakeStore {
    /// Runs the call; nil while another runs.
    func run(_ kind: MakeKind, job: @escaping @MainActor () async throws -> Artefact) -> Task<Artefact?, Never>? {
        guard running == nil else { return nil }
        failure = nil
        running = Running(kind: kind, title: kind.making)
        let task = Task { [weak self] () -> Artefact? in
            do {
                let artefact = try await job()
                guard !Task.isCancelled, let self else { return nil }
                running = nil
                self.task = nil
                kept(artefact)
                return artefact
            } catch {
                guard !Task.isCancelled, let self else { return nil }
                running = nil
                self.task = nil
                failure = Failure(kind: kind, message: Self.words(for: error), canRetry: Self.canRetry(error))
                return nil
            }
        }
        self.task = task
        return task
    }

    static func words(for error: any Error) -> String {
        switch error {
        case let failure as APIFailure: failure.message
        case is MakeRefusal: MakeWords.figureRefused
        default: "That didn't go through. Check your connection and try again."
        }
    }

    static func canRetry(_ error: any Error) -> Bool {
        switch error as? APIFailure {
        case .limit?, .allowance?, .studentConsent?, .consent?, .signedOut?: false
        default: true
        }
    }
}

/// A figure whose spec breaks the app's own rule (D59): refused in words, nothing kept.
struct MakeRefusal: Error {}
