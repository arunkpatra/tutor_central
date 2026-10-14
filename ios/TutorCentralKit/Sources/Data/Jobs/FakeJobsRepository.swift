import Domain
import Foundation

/// Jobs in memory, for tests, previews and `bun shots`: the plan job each batch and day answers, a record of each
/// request and cancel, and each read.
@MainActor public final class FakeJobsRepository: JobsRepository {
    public enum Request: Hashable, Sendable {
        case plan(classID: UUID, date: Day, choices: PlanChoices?)
        case note(student: UUID, week: Day)
        case export(student: UUID)
    }

    /// The plan job a read answers, by batch; set by a test to move a job on.
    public var planJobs: [UUID: JobStatus]
    /// The export job a read answers, by student.
    public var exportJobs: [UUID: JobStatus] = [:]
    /// By exam item: its job (D106).
    public var examJobs: [UUID: ExamJobStatus] = [:]
    /// The items whose exam job was asked or woken, in order.
    public private(set) var examPrepRequests: [UUID] = []
    /// What a request leaves for its batch: a live job, unless a test says otherwise.
    public var afterRequest: JobStatus.State = .queued
    /// The server's work for a plan request, for `bun shots`: the plan written and the job's state after it.
    public var onPlanRequest: (@MainActor (UUID, Day, PlanChoices?) async -> JobStatus.State)?
    /// The server's work for a note request, for `bun shots` and the tests: the note kept for the student and week.
    public var onNoteRequest: (@MainActor (UUID, Day) async -> Void)?
    public var failure: (any Error)?
    /// A failure of the plan job's read alone (a request still goes through).
    public var planReadFailure: (any Error)?
    public private(set) var requested: [Request] = []
    public private(set) var cancelled: [UUID] = []
    public private(set) var reads = 0
    private let now: @Sendable () -> Date

    public init(planJobs: [UUID: JobStatus] = [:], now: @escaping @Sendable () -> Date = { Date() }) {
        self.planJobs = planJobs
        self.now = now
    }

    public func planJob(centre _: UUID, classID: UUID, date _: Day) async throws -> JobStatus? {
        reads += 1
        if let failure = failure ?? planReadFailure {
            throw failure
        }
        return planJobs[classID]
    }

    public func requestPlan(centre _: UUID, classID: UUID, date: Day, choices: PlanChoices?) async throws -> UUID {
        if let failure {
            throw failure
        }
        requested.append(.plan(classID: classID, date: date, choices: choices))
        if let live = planJobs[classID], live.isLive {
            return live.id
        }
        let created = now()
        let state = await onPlanRequest?(classID, date, choices) ?? afterRequest
        let job = JobStatus(id: UUID(), state: state, createdAt: created)
        planJobs[classID] = job
        return job.id
    }

    public func requestNote(centre _: UUID, student: UUID, week: Day) async throws -> UUID {
        if let failure {
            throw failure
        }
        requested.append(.note(student: student, week: week))
        await onNoteRequest?(student, week)
        return UUID()
    }

    public func exportJob(centre _: UUID, student: UUID) async throws -> JobStatus? {
        reads += 1
        if let failure {
            throw failure
        }
        return exportJobs[student]
    }

    public func requestExport(centre _: UUID, student: UUID) async throws -> UUID {
        if let failure {
            throw failure
        }
        requested.append(.export(student: student))
        if let live = exportJobs[student], live.isLive {
            return live.id
        }
        let job = JobStatus(id: UUID(), state: afterRequest, createdAt: now())
        exportJobs[student] = job
        return job.id
    }

    public func examJob(centre _: UUID, item: UUID) async throws -> ExamJobStatus? {
        if let failure {
            throw failure
        }
        return examJobs[item]
    }

    public func requestExamPrep(centre _: UUID, item: UUID) async throws -> UUID {
        if let failure {
            throw failure
        }
        examPrepRequests.append(item)
        return UUID()
    }

    public func cancel(centre _: UUID, job: UUID) async throws {
        if let failure {
            throw failure
        }
        cancelled.append(job)
        for (classID, status) in planJobs where status.id == job && status.isLive {
            planJobs[classID] = JobStatus(id: job, state: .cancelled, createdAt: status.createdAt, finishedAt: now())
        }
    }
}
