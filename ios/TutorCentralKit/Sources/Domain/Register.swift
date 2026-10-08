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
    /// Reads only when nothing has been read or cached yet.
    func loadIfNeeded() async
}
