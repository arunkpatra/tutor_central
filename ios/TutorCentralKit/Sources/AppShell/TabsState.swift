import Domain
import Foundation
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

    /// Takes a screen that cannot show (a link to a student no longer here) off whichever stack holds it.
    func remove(_ route: Route) {
        for tab in paths.keys {
            paths[tab]?.removeAll { $0 == route }
        }
    }

    /// A link opens its tab at the root, then its screen (a student's detail; the fees month is set by the caller).
    /// Returns false when this build has no screen for it, so the caller can say so.
    func open(_ link: DeepLink) -> Bool {
        selected = link.tab
        paths[link.tab] = []
        switch link {
        case .today, .authCallback, .attendance: return true
        case let .event(id):
            paths[link.tab] = [.event(id)]
            return true
        case let .student(id):
            paths[link.tab] = [.student(id)]
            return true
        case .fees: return true
        }
    }
}

/// The screens a tab's stack can push in this build.
enum Route: Hashable {
    case settings
    /// Account, from Settings and More; Delete account from it.
    case account
    case deleteAccount
    /// Help, from Settings and More.
    case help
    /// Pending changes, from Settings and the failure line on every root.
    case pendingChanges
    case student(UUID)
    case classes
    case classroom(UUID)
    case history
    case historyStudent(UUID)
    case schedule
    /// The schedule with an event's Edit sheet open (`tutorcentral://event/<id>`).
    case event(UUID)
    case tasks
    /// A student's fees, from the detail's See all.
    case studentFees(UUID)
    /// Parent payments, from Settings' row and Fees' Payments.
    case payments
    /// Reports, from More.
    case reports
    /// The AI Assistant, from More and from Today's Create row; its forms, results and History on the same stack.
    case aiAssistant
    case aiForm(GenerationKind)
    case aiResult(UUID)
    case aiHistory
    /// Scan register, from More, the Students "+" menu and the empty register.
    case scanRegister
    /// Check a paper, one visit's steps sharing its store (the id): the intro, the pages, the scheme, the marks.
    case checkPaper(UUID)
    case checkPages(UUID)
    case checkScheme(UUID)
    case checkResult(UUID)
}
