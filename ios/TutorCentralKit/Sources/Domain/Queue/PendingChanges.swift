import Foundation

/// The changes waiting on this iPhone, in the order they were made (D39). Last write wins on the phone too: a second
/// attendance save of the same class and day, or a second Mark paid of the same invoice, replaces the first in its
/// place.
public struct PendingChanges: Hashable, Sendable, Codable {
    public private(set) var changes: [QueuedChange] = []

    public init(changes: [QueuedChange] = []) {
        self.changes = changes
    }

    public mutating func add(_ change: QueuedChange) {
        guard let index = changes.firstIndex(where: { Self.sameRow($0.kind, change.kind) }) else {
            changes.append(change)
            return
        }
        let earlier = changes[index]
        changes[index] = QueuedChange(id: earlier.id, kind: change.kind, madeAt: earlier.madeAt)
    }

    public mutating func remove(id: UUID) {
        changes.removeAll { $0.id == id }
    }

    public mutating func fail(id: UUID, reason: String) {
        guard let index = changes.firstIndex(where: { $0.id == id }) else { return }
        changes[index].state = .failed(reason: reason)
    }

    /// Failed changes wait again (Send again).
    public mutating func retryAll() {
        for index in changes.indices {
            changes[index].state = .waiting
        }
    }

    /// The waiting changes by the time they were made: the replay's order.
    public var inOrder: [QueuedChange] {
        changes.enumerated().filter { $0.element.state == .waiting }
            .sorted { ($0.element.madeAt, $0.offset) < ($1.element.madeAt, $1.offset) }.map(\.element)
    }

    public var waitingCount: Int {
        changes.count { $0.state == .waiting }
    }

    public var failedCount: Int {
        changes.count - waitingCount
    }

    public var isEmpty: Bool {
        changes.isEmpty
    }

    /// "2 saved changes haven't been sent yet: attendance for Class 10 Maths and Dev's fee."; nil when none.
    public var signOutWarning: String? {
        guard !changes.isEmpty else { return nil }
        let names = changes.sorted { $0.madeAt < $1.madeAt }.map(\.shortName)
        let list = names.count == 1 ? names[0] : names.dropLast()
            .joined(separator: ", ") + " and " + names[names.count - 1]
        let lead = changes.count == 1
            ? "1 saved change hasn't"
            : "\(changes.count) saved changes haven't"
        return "\(lead) been sent yet: \(list)."
    }

    /// Whether a change of that kind waits, so a new write of the kind joins the queue behind it.
    public func has(kind: QueuedChangeCase) -> Bool {
        changes.contains { $0.kind.case == kind }
    }

    private static func sameRow(_ lhs: QueuedChange.Kind, _ rhs: QueuedChange.Kind) -> Bool {
        switch (lhs, rhs) {
        case let (.attendance(leftClass, _, leftDate, _, _, _), .attendance(rightClass, _, rightDate, _, _, _)):
            leftClass == rightClass && leftDate == rightDate
        case let (.markPaid(leftInvoice, _, _, _, _, _), .markPaid(rightInvoice, _, _, _, _, _)):
            leftInvoice == rightInvoice
        default:
            false
        }
    }
}
