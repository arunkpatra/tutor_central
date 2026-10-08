/// A mark (`attendance_marks.status`). Late is out of scope (functional-inventory.md).
public enum AttendanceStatus: String, Hashable, Sendable, Codable {
    case present
    case absent
}
