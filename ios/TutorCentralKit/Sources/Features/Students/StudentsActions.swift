import Domain
import Foundation

/// Where the Students tab's buttons lead when the screen is another feature's (the scan, a student's fees, marking
/// attendance); AppShell supplies them, as Today's `TodayActions`.
public struct StudentsActions {
    let openScanRegister: () -> Void
    let openStudentFees: (UUID) -> Void
    let openMarkAttendance: (UUID) -> Void
    let openStudentAttendance: (UUID) -> Void
    /// Remind and Mark paid on the detail's fee row: the Fees tab at that month with the sheet open.
    let openFeeAction: (FeeAction) -> Void

    public init(
        openScanRegister: @escaping () -> Void,
        openStudentFees: @escaping (UUID) -> Void,
        openMarkAttendance: @escaping (UUID) -> Void,
        openStudentAttendance: @escaping (UUID) -> Void,
        openFeeAction: @escaping (FeeAction) -> Void
    ) {
        self.openScanRegister = openScanRegister
        self.openStudentFees = openStudentFees
        self.openMarkAttendance = openMarkAttendance
        self.openStudentAttendance = openStudentAttendance
        self.openFeeAction = openFeeAction
    }
}
