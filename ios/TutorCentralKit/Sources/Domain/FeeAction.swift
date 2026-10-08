import Foundation

/// What the Students tab asks the Fees tab to do for a student's month (the detail's and the student's fees' Remind
/// and Mark paid open on the Fees tab, as Mark attendance opens on the Attendance tab).
public enum FeeAction: Hashable, Sendable {
    case remind(studentID: UUID, month: Period)
    case markPaid(studentID: UUID, month: Period)
}
