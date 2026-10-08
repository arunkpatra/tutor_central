import Data
import Domain
import Foundation
import Observation

/// Today's heading, greeting and counts. A refresh that fails keeps the last numbers and says so (the stale pattern).
@MainActor @Observable public final class TodayStore {
    public private(set) var counts: TodayCounts = .zero
    public private(set) var loading = false
    public private(set) var error: String?
    public private(set) var workspace: Workspace
    private let repository: any CountsRepository
    private let now: () -> Date
    private var loaded = false

    public init(workspace: Workspace, counts: any CountsRepository, now: @escaping () -> Date) {
        self.workspace = workspace
        repository = counts
        self.now = now
    }

    public var heading: String {
        DayHeading.long(now(), calendar: DayHeading.india)
    }

    public var greeting: String {
        Greeting.text(at: now(), firstName: workspace.profile.firstName, calendar: DayHeading.india)
    }

    public var initials: String {
        workspace.profile.initials
    }

    /// Settings edits the name; the greeting and initials follow.
    public func workspaceChanged(_ workspace: Workspace) {
        self.workspace = workspace
    }

    public func load() async {
        if !loaded {
            loading = true
        }
        defer { loading = false }
        do {
            counts = try await repository.todayCounts(centre: workspace.centre.id, on: now())
            error = nil
            loaded = true
        } catch {
            self.error = "Couldn't refresh. Check your connection and try again."
        }
    }
}

/// Where Today's buttons lead; AppShell supplies them (a feature never imports another).
public struct TodayActions {
    let openSettings: () -> Void
    let openTab: (AppTab) -> Void
    let openLater: (LaterTarget) -> Void
    let openSchedule: () -> Void

    public init(
        openSettings: @escaping () -> Void,
        openTab: @escaping (AppTab) -> Void,
        openLater: @escaping (LaterTarget) -> Void,
        openSchedule: @escaping () -> Void
    ) {
        self.openSettings = openSettings
        self.openTab = openTab
        self.openLater = openLater
        self.openSchedule = openSchedule
    }

    /// Today's actions whose screens arrive in later builds.
    public enum LaterTarget: Sendable {
        case tasks
        case students
    }
}
