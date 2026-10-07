import Domain
import Observation
import SwiftUI

/// Where the tutor is in the tabs: the selected tab and each tab's own stack (information-architecture.md, "Tabs").
@MainActor @Observable final class TabsState {
    var selected: AppTab
    var paths: [AppTab: [Route]] = [:]

    init(selected: AppTab = .today) {
        self.selected = selected
    }

    /// Tapping the active tab pops it to its root.
    func select(_ tab: AppTab) {
        if tab == selected {
            paths[tab] = []
        }
        selected = tab
    }

    func push(_ route: Route) {
        paths[selected, default: []].append(route)
    }

    /// A link opens its tab at the root; its screen arrives with its phase. Returns false when this build has no
    /// screen for it, so the caller can say so.
    func open(_ link: DeepLink) -> Bool {
        selected = link.tab
        paths[link.tab] = []
        switch link {
        case .today, .authCallback: return true
        case .student, .fees, .attendance, .event: return false
        }
    }
}

/// The screens a tab's stack can push in this build.
enum Route: Hashable {
    case later(LaterPlace)
    case settings
}
