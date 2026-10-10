import Domain
import Foundation
import Supabase

/// What a run of the queue came to.
public enum RunOutcome: Hashable, Sendable {
    /// `sent` were sent; `failed` were refused by the server (now failed in the queue); nothing waits.
    case done(sent: Int, failed: Int)
    /// The transport failed after `sent` sends; the rest still wait.
    case offline(sent: Int)
    /// A 401: the rest wait until the tutor signs in again.
    case signedOut(sent: Int)
}

/// Replays the queue (D39): in the order made, one at a time, each on its own. Last write wins per row (the phone's
/// write replaces the server's). A transport failure stops the run and keeps the change; a 401 stops it as signed
/// out; a row the server refuses is failed with its reason and the run goes on.
@MainActor public final class QueueRunner {
    public let queue: ChangeQueue
    public private(set) var running = false
    private let centre: UUID
    private let attendance: any AttendanceRepository
    private let fees: any FeesRepository
    private let messages: any MessageLogRepository

    public init(
        queue: ChangeQueue, centre: UUID, attendance: any AttendanceRepository, fees: any FeesRepository,
        messages: any MessageLogRepository
    ) {
        self.queue = queue
        self.centre = centre
        self.attendance = attendance
        self.fees = fees
        self.messages = messages
    }

    /// Sends every waiting change in order until none waits; refused while a run is in progress (answers nil). The
    /// queue is read again before each send, so a change undone or discarded meanwhile is not sent, and one added or
    /// corrected meanwhile goes in this run.
    public func run() async -> RunOutcome? {
        guard !running else { return nil }
        running = true
        defer { running = false }
        var sent = 0
        var failed = 0
        while let change = queue.pending.inOrder.first {
            do {
                try await send(change)
                queue.removeSent(change)
                sent += 1
            } catch {
                switch Self.classify(error) {
                case .offline: return .offline(sent: sent)
                case .signedOut: return .signedOut(sent: sent)
                case .refused:
                    queue.fail(id: change.id, reason: Self.reason(for: change, error: error))
                    failed += 1
                }
            }
        }
        return .done(sent: sent, failed: failed)
    }

    private func send(_ change: QueuedChange) async throws {
        switch change.kind {
        case let .attendance(classID, _, date, marks, _, _):
            _ = try await attendance.save(centre: centre, classID: classID, date: date, marks: marks)
        case let .markPaid(invoiceID, _, _, _, method, paidAt):
            _ = try await fees.markPaid(id: invoiceID, method: method, at: paidAt)
        case let .absenceLog(studentID, _, about):
            _ = try await messages.logAbsence(centre: centre, studentID: studentID, about: about)
        case let .close(close, _, _, _):
            _ = try await attendance.close(close, centre: centre)
        }
    }

    enum Kind {
        case offline, signedOut, refused
    }

    /// Wait, or fail. Anything on the way (no network, a gateway's 5xx, a cancelled request) waits for the next run;
    /// only the database refusing the row (a PostgREST code) fails it.
    static func classify(_ error: any Error) -> Kind {
        if TransportError.isOffline(error) || TransportError.isCancelled(error) || error is URLError {
            return .offline
        }
        switch error {
        case AuthError.sessionMissing: return .signedOut
        case let .api(_, _, _, response) as AuthError where response.statusCode == 401: return .signedOut
        case let postgrest as PostgrestError where postgrest.code == "PGRST301": return .signedOut
        case let http as HTTPError where http.response.statusCode == 401: return .signedOut
        case let http as HTTPError where http.response.statusCode >= 500: return .offline
        case let postgrest as PostgrestError where postgrest.code == nil: return .offline
        default: return .refused
        }
    }

    /// The reason a refused change carries: the student or class gone, else the server's words.
    public static func reason(for change: QueuedChange, error: any Error) -> String {
        let code = (error as? PostgrestError)?.code
        let gone = code == "PGRST116" || code == "23503"
        let keep = "Keep it here or discard it."
        switch change.kind {
        case let .attendance(classID, className, _, _, _, _) where gone:
            let studentGone = (error as? PostgrestError)?.message.contains("attendance_marks") == true || classID == nil
            return studentGone
                ? "A student marked here is no longer in the register, so this attendance can't be saved. \(keep)"
                : "\(className) is no longer here, so this attendance can't be saved. \(keep)"
        case let .close(_, className, _, _) where gone:
            let message = (error as? PostgrestError)?.message ?? ""
            let studentGone = ["attendance_marks", "checks", "homework", "skills"].contains { message.contains($0) }
            return studentGone
                ? "A student marked here is no longer in the register, so this close can't be saved. \(keep)"
                : "\(className) is no longer here, so this close can't be saved. \(keep)"
        case let .markPaid(_, studentName, _, _, _, _) where gone:
            return "\(studentName) is no longer in the register, so their fee can't be marked. \(keep)"
        case let .absenceLog(_, studentName, _) where gone:
            return "\(studentName) is no longer in the register, so the absence alert can't be noted. \(keep)"
        default:
            // Never the backend's own words on screen: they are technical (the owner, 2026-10-09).
            return "This change couldn't be saved. \(keep)"
        }
    }
}
