/// The five tabs, in order. Lives in Domain so a feature can ask AppShell to switch tabs without importing it.
public enum AppTab: String, CaseIterable, Sendable, Hashable {
    case today
    case students
    case fees
    case attendance
    case more
}
