/// Where the Attendance tab's buttons lead when the screen is another feature's or AppShell's; AppShell supplies them.
public struct AttendanceActions {
    let openStudents: () -> Void
    let openHistory: () -> Void

    public init(openStudents: @escaping () -> Void, openHistory: @escaping () -> Void) {
        self.openStudents = openStudents
        self.openHistory = openHistory
    }
}
