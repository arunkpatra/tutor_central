import Foundation

/// The centre's students and classes as another screen reads them. `RegisterStore` (Students) is the one per centre;
/// AppShell hands it to Attendance, Schedule and Today as `any Register`, so features never import each other and the
/// register is never read twice.
@MainActor public protocol Register: AnyObject {
    var activeStudents: [Student] { get }
    var activeClasses: [Classroom] { get }
    func members(of classID: UUID) -> [Student]
    func student(_ id: UUID) -> Student?
    func classroom(_ id: UUID?) -> Classroom?
    /// True only once a read said the centre has no students: never while loading or after a failed first read.
    var showsEmptyRegister: Bool { get }
    /// Reads only when nothing has been read or cached yet.
    func loadIfNeeded() async
    /// The close's statuses on the register's students at once (the write sets them on the server).
    func applyTracking(_ track: [UUID: SessionClose.Track], at date: Date)
    /// A batch as a write answered it (the note day, Phase 14), in place of the register's copy.
    func applyClassroom(_ classroom: Classroom)
}

public extension Register {
    /// A message about this student or another student of the same parent (the same number): the cadence counts a
    /// parent's week across their students.
    func sameParent(_ id: UUID, _ student: Student) -> Bool {
        guard let number = student.parentPhone?.e164 else { return id == student.id }
        return id == student.id || self.student(id)?.parentPhone?.e164 == number
    }
}
