import Data
import Domain
import Foundation
import Observation

/// Pending changes (P7-Pending): every change kept on this iPhone in the order made, waiting or failed with its
/// reason; Discard (after its dialog) drops one, the server's state standing; Send again retries the failed ones and
/// sends the rest through AppShell's runner.
@MainActor @Observable public final class PendingChangesStore {
    public var confirmingDiscard: UUID?
    public private(set) var sending = false
    private let queue: ChangeQueue
    private let calendar: Calendar
    private let send: @MainActor () async -> RunOutcome?

    public init(queue: ChangeQueue, calendar: Calendar, send: @escaping @MainActor () async -> RunOutcome?) {
        self.queue = queue
        self.calendar = calendar
        self.send = send
    }

    /// Waiting and failed, in the order made.
    public var rows: [QueuedChange] {
        queue.pending.changes.sorted { $0.madeAt < $1.madeAt }
    }

    public var canSend: Bool {
        !sending && !queue.pending.isEmpty
    }

    public func line(for change: QueuedChange) -> String {
        change.line(calendar: calendar)
    }

    public func discard(id: UUID) {
        queue.remove(id: id)
        confirmingDiscard = nil
    }

    /// The failed ones wait again, then everything goes in order.
    public func sendAgain() async -> RunOutcome? {
        guard canSend else { return nil }
        sending = true
        defer { sending = false }
        queue.retryAll()
        return await send()
    }

    /// The dialog's body: what stands on the server and what is lost here.
    public func discardWords(for id: UUID) -> String {
        guard let change = queue.pending.changes.first(where: { $0.id == id }) else { return "" }
        switch change.kind {
        case let .attendance(_, className, date, _, _, _):
            return "Attendance for \(className) on \(date.shortWeekdayText) stays as it was. "
                + "What you marked here is lost."
        case .markPaid where change.state != .waiting:
            // A failed change: the server already refused it, so nothing there changes either way.
            return "The mark you made here is lost. Nothing else changes."
        case let .markPaid(_, studentName, month, _, _, _):
            return "\(Self.firstName(studentName))'s \(month.monthName) fee stays as it was: due. "
                + "The mark you made here is lost."
        case let .absenceLog(_, studentName, _):
            return "The absence alert for \(Self.firstName(studentName)) isn't noted on their page. "
                + "WhatsApp already opened."
        }
    }

    private static func firstName(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name
    }
}
