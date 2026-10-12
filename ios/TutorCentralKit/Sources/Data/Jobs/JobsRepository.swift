import Domain
import Foundation

/// A job the server does for the centre (D71), as the app reads it: live while queued, running or waiting, then done,
/// failed or cancelled.
public struct JobStatus: Hashable, Sendable {
    public enum State: String, Hashable, Sendable, Decodable {
        case queued, running, waiting, done, failed, cancelled
    }

    public let id: UUID
    public let state: State
    public let createdAt: Date
    public let finishedAt: Date?
    /// The result's reason for a job done without its work ("closed", "holiday", "no_members"), else nil.
    public let reason: String?
    /// The file a job made (a student's export): where it is, its pages and when it was made.
    public let file: JobFile?

    public init(
        id: UUID, state: State, createdAt: Date, finishedAt: Date? = nil, reason: String? = nil, file: JobFile? = nil
    ) {
        self.id = id
        self.state = state
        self.createdAt = createdAt
        self.finishedAt = finishedAt
        self.reason = reason
        self.file = file
    }

    public var isLive: Bool {
        [.queued, .running, .waiting].contains(state)
    }
}

/// A file a job made: its path in the bucket, its pages, when it was made.
public struct JobFile: Hashable, Sendable {
    public let path: String
    public let pages: Int
    public let madeAt: Date

    public init(path: String, pages: Int, madeAt: Date) {
        self.path = path
        self.pages = pages
        self.madeAt = madeAt
    }
}

/// The server's jobs for the centre (`jobs`, members read their centre's rows) and the requests a member may make
/// (0037: `request_plan`, `request_note`, `request_export`; 0028: `cancel_job`). A request answers the live job for the
/// same subject, so
/// a second tap
/// starts nothing.
public protocol JobsRepository: Sendable {
    /// The newest plan job for the batch and day; none when the server has not been asked.
    func planJob(centre: UUID, classID: UUID, date: Day) async throws -> JobStatus?
    /// A plan for the batch and day; `choices` (the Change sheet's) replace the day's plan unless it is closed.
    func requestPlan(centre: UUID, classID: UUID, date: Day, choices: PlanChoices?) async throws -> UUID
    func cancel(centre: UUID, job: UUID) async throws
    /// A student's note for the week the note day did not write (`request_note`; the week named by its Monday); the job
    /// keeps it as the note day's would.
    func requestNote(centre: UUID, student: UUID, week: Day) async throws -> UUID
    /// The newest export job for the student; none when none was asked for.
    func exportJob(centre: UUID, student: UUID) async throws -> JobStatus?
    /// A student's export (`request_export`): everything kept about them in one PDF.
    func requestExport(centre: UUID, student: UUID) async throws -> UUID
}

/// Today's choices from the Change sheet, as the plan job reads them: the group count and each group's subject; nil
/// fields leave them to the batch's pattern and the rules.
public struct PlanChoices: Hashable, Sendable {
    public var groups: Int?
    public var subjects: [Int: String]

    public init(groups: Int?, subjects: [Int: String]) {
        self.groups = groups
        self.subjects = subjects
    }
}
