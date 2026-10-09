import Data
import Domain
import Foundation
import Observation

/// Delete account (P7-Delete, D37, D38): what goes, the centre's name typed, then Apple's confirmation and revocation
/// for an Apple account, then `delete_account()`. A failure before the deletion leaves everything and the tutor signed
/// in; Retry runs every step again (a second Apple authorization gives a fresh code). The run is the store's task:
/// refused while one runs; Back cancels it and a late answer is dropped. Once the account is deleted, `onDeleted` (the
/// wipe, the landing) runs whatever happened to the screen.
@MainActor @Observable public final class DeleteAccountStore {
    public struct Failure: Equatable, Sendable {
        public let title: String
        public let line: String
    }

    public enum Phase: Equatable, Sendable {
        case idle
        case confirmingWithApple
        case deleting
        case failed(Failure)
        case done
    }

    public var typed = ""
    public private(set) var phase: Phase = .idle
    public private(set) var notices: [String] = []
    public private(set) var needsApple = false
    public let centreName: String
    private let register: any Register
    private let auth: any AuthRepository
    private let account: any AccountRepository
    private let reauthorize: @MainActor () async throws(AccountFailure) -> String
    private let onDeleted: @MainActor () async -> Void
    private var generation = 0
    private var run: Task<Void, Never>?

    public init(
        workspace: Workspace, register: any Register, auth: any AuthRepository, account: any AccountRepository,
        reauthorize: @escaping @MainActor () async throws(AccountFailure) -> String,
        onDeleted: @escaping @MainActor () async -> Void
    ) {
        centreName = workspace.centre.name
        self.register = register
        self.auth = auth
        self.account = account
        self.reauthorize = reauthorize
        self.onDeleted = onDeleted
    }

    /// The methods (whether Apple must confirm) and the register's counts for the notices.
    public func load() async {
        needsApple = await auth.signInMethods().contains(.apple)
        await register.loadIfNeeded()
        notices = Self.notices(students: register.activeStudents.count, classes: register.activeClasses.count)
            + ["Your sign-in. Signing in again later starts a new, empty centre."]
            + (needsApple ? [Self.appleNotice] : [])
    }

    static let appleNotice = "Apple is asked to forget this app, so your Apple ID no longer lists it. You confirm "
        + "with Apple first."

    public var busy: Bool {
        phase == .confirmingWithApple || phase == .deleting
    }

    public var canDelete: Bool {
        !busy && phase != .done && DeletionConfirmation.matches(typed: typed, centreName: centreName)
    }

    /// Runs the deletion in the store's task; refused while one runs.
    public func delete() async {
        guard canDelete else { return }
        generation += 1
        let task = Task { [generation] in await perform(generation) }
        run = task
        await task.value
    }

    /// Back while it runs: the task is cancelled and its answer dropped.
    public func cancel() {
        generation += 1
        run?.cancel()
        run = nil
        if busy {
            phase = .idle
        }
    }

    private func perform(_ mine: Int) async {
        do {
            if needsApple {
                phase = .confirmingWithApple
                let code = try await reauthorize()
                guard mine == generation else { return }
                try await account.revokeApple(code: code)
                guard mine == generation else { return }
            }
            phase = .deleting
            try await auth.deleteAccount()
            // The account is gone whatever the screen does now: the deletion's own sign-out can take the screen away
            // before this line, so the wipe and the landing's words run here, from the store's task.
            await onDeleted()
            phase = .done
        } catch {
            guard mine == generation else { return }
            phase = error == .cancelled ? .idle : .failed(Self.failure(error))
        }
    }

    /// "10 students with their fees and attendance, 2 classes, …"; without numbers when nothing is read.
    static func notices(students: Int, classes: Int) -> [String] {
        let rest = "your events, tasks, notes and everything created with AI."
        guard students > 0 || classes > 0 else {
            return ["Your students with their fees and attendance, your classes, \(rest)"]
        }
        let studentWords = "\(students) \(students == 1 ? "student" : "students")"
        let classWords = "\(classes) \(classes == 1 ? "class" : "classes")"
        return ["\(studentWords) with their fees and attendance, \(classWords), \(rest)"]
    }

    static func failure(_ error: AccountFailure) -> Failure {
        if error == .signedOut {
            return Failure(
                title: "Couldn't delete your account.",
                line: "Your sign-in has ended. Sign in again and try once more. Nothing was removed."
            )
        }
        let what = switch error {
        case .offline: "Check your connection and try again."
        default: error.message
        }
        return Failure(
            title: "Couldn't delete your account.", line: "\(what) Nothing was removed; you are still signed in."
        )
    }
}
