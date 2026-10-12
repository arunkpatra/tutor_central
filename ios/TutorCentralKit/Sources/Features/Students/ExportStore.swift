import Data
import Domain
import Foundation
import Observation

/// A student's export (P18-Export-Ask, -Making, -Ready, -Failed; D79): everything kept about them in one PDF, made by
/// the server's export job and kept seven days. Asked from the page's Export section; while it is made the store reads
/// the job every five seconds while the page is in front; Share downloads the file once.
@MainActor @Observable public final class ExportStore {
    public enum State: Hashable, Sendable {
        case ask
        case making(askedAt: Date)
        case ready(JobFile)
        case failed
    }

    public private(set) var state: State = .ask
    public private(set) var asking = false
    /// The file for the share sheet once downloaded.
    public private(set) var shared: URL?
    /// Words for the system alert: a refused or failed ask, a file that could not be had (U33).
    public var failure: String?
    public let studentID: UUID
    let register: RegisterStore
    let jobs: any JobsRepository
    let files: ServerFiles?
    let now: @Sendable () -> Date
    let online: @Sendable () async -> Bool
    let pause: @Sendable () async throws -> Void
    /// Whether the page is in front (AppShell's): the reads while the file is made stop behind it.
    @ObservationIgnored public var inFront: () -> Bool = { true }
    @ObservationIgnored var following: Task<Void, Never>?

    /// How long the file is kept on the server (the sweep's retention).
    static let kept: TimeInterval = 7 * 86400

    public init(
        studentID: UUID, register: RegisterStore, jobs: any JobsRepository, files: ServerFiles?,
        now: @escaping @Sendable () -> Date, online: @escaping @Sendable () async -> Bool,
        pause: @escaping @Sendable () async throws -> Void = { try await Task.sleep(for: .seconds(5)) }
    ) {
        self.studentID = studentID
        self.register = register
        self.jobs = jobs
        self.files = files
        self.now = now
        self.online = online
        self.pause = pause
    }

    /// The newest export job: being made, ready (unless older than seven days), not made, or none.
    public func load() async {
        guard let job = try? await jobs.exportJob(centre: register.workspace.centre.id, student: studentID) else {
            return
        }
        show(job)
        if job.isLive {
            follow()
        }
    }

    /// Make the file, Make again, Try Again: a new export asked of the server; offline refused in the consent's words.
    public func make() async {
        guard !asking else { return }
        guard await online() else {
            failure = OfflineRefusal.words(for: .consent)
            return
        }
        asking = true
        defer { asking = false }
        do {
            _ = try await jobs.requestExport(centre: register.workspace.centre.id, student: studentID)
        } catch {
            failure = TransportError.isOffline(error) ? OfflineRefusal.words(for: .consent)
                : "That didn't go through. Check your connection and try again."
            return
        }
        shared = nil
        state = .making(askedAt: now())
        follow()
    }

    /// Share: the file downloaded once and handed to the share sheet (`shared`).
    public func share() async {
        guard case let .ready(file) = state, let files else { return }
        do {
            shared = try await files.file(bucket: "exports", path: file.path, named: fileName)
        } catch {
            failure = TransportError.isOffline(error) ? OfflineRefusal.words(for: .consent)
                : "That didn't go through. Check your connection and try again."
        }
    }

    /// The share sheet closed.
    public func shareDone() {
        shared = nil
    }

    func show(_ job: JobStatus) {
        switch job.state {
        case .queued, .running, .waiting:
            state = .making(askedAt: job.createdAt)
        case .done:
            guard let file = job.file, now().timeIntervalSince(file.madeAt) < Self.kept else {
                state = .ask
                return
            }
            state = .ready(file)
        case .failed:
            state = .failed
        case .cancelled:
            state = .ask
        }
    }

    /// Reads the job every five seconds while it is made and the page is in front.
    func follow() {
        guard following == nil else { return }
        following = Task { [weak self] in
            while !Task.isCancelled {
                guard let pause = self?.pause, await (try? pause()) != nil, let self, inFront(),
                      let job = try? await jobs.exportJob(centre: register.workspace.centre.id, student: studentID)
                else { break }
                show(job)
                guard job.isLive else { break }
            }
            self?.following = nil
        }
    }

    /// The page leaves: the reads stop.
    public func stop() {
        following?.cancel()
        following = nil
    }

    var fileName: String {
        "\(register.student(studentID)?.name ?? "Student") · everything kept"
    }
}
