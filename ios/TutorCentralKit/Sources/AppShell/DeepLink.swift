import Domain
import Foundation

/// The app's links (information-architecture.md, "Deep links"): `tutorcentral://<place>`. Notifications carry them
/// from Phase 7; the auth callback is Google's web session coming back.
public enum DeepLink: Equatable, Sendable {
    case today
    case student(UUID)
    case fees(month: String?)
    case attendance(date: String?, classID: UUID?)
    case event(UUID)
    case authCallback

    public init?(url: URL) {
        guard url.scheme == "tutorcentral", let place = url.host() else { return nil }
        let rest = Array(url.pathComponents.dropFirst())
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            query.first { $0.name == name }?.value
        }
        switch (place, rest.first.flatMap(UUID.init(uuidString:))) {
        case ("today", _): self = .today
        case let ("student", id?): self = .student(id)
        case ("fees", _): self = .fees(month: value("month"))
        case ("attendance", _): self = .attendance(date: value("date"), classID: value("class").flatMap(UUID.init))
        case let ("event", id?): self = .event(id)
        case ("auth-callback", _): self = .authCallback
        default: return nil
        }
    }

    /// The tab whose stack the link opens on.
    public var tab: AppTab {
        switch self {
        case .today, .authCallback: .today
        case .student: .students
        case .fees: .fees
        case .attendance: .attendance
        case .event: .more
        }
    }
}
