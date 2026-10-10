/// The five tabs, in order. Lives in Domain so a feature can ask AppShell to switch tabs without importing it.
public enum AppTab: String, CaseIterable, Sendable, Hashable {
    case today
    case students
    /// V2 (Phase 11): the School tab; Attendance moved under More (D65).
    case school
    case fees
    case more
}
