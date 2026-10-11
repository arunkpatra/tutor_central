import Data
import Domain
import Foundation
import Observation
import School
import SwiftUI

/// Where the tutor is in the tabs: the selected tab and each tab's own stack (information-architecture.md, "Tabs").
@MainActor @Observable final class TabsState {
    var selected: AppTab
    var paths: [AppTab: [Route]] = [:]
    /// Counts the pushes of Scan register: each is a new visit with its own store (`ShellState.scan`).
    @ObservationIgnored private(set) var scanVisits = 0
    /// A tab chosen in the tab bar or by a link: the School tab's student filter is cleared (U42).
    @ObservationIgnored var onTabChosen: (() -> Void)?

    /// Scan register is on some tab's stack; when it goes (Back, Add, a tab popped to its root) the visit ends.
    var scanOnStack: Bool {
        paths.values.contains { $0.contains(.scanRegister) }
    }

    init(selected: AppTab = .today) {
        self.selected = selected
    }

    /// The tab bar's choice: as `select`, and the School filter cleared.
    func choose(_ tab: AppTab) {
        onTabChosen?()
        select(tab)
    }

    /// Tapping the active tab pops it to its root.
    func select(_ tab: AppTab) {
        if tab == selected {
            paths[tab] = []
        }
        selected = tab
    }

    func push(_ route: Route) {
        if route == .scanRegister {
            scanVisits += 1
        }
        paths[selected, default: []].append(route)
    }

    /// Takes a screen that cannot show (a link to a student no longer here) off whichever stack holds it.
    func remove(_ route: Route) {
        for tab in paths.keys {
            paths[tab]?.removeAll { $0 == route }
        }
    }

    /// Attendance's mark root on the tab that asked (Today's Mark attendance, a batch's, History's session, a student's
    /// month): pushed, or come back to when it is already on that stack, so History's session does not stack a second.
    func showAttendance() {
        var path = paths[selected, default: []]
        if let index = path.lastIndex(of: .attendance) {
            path.removeSubrange((index + 1)...)
        } else {
            path.append(.attendance)
        }
        paths[selected] = path
    }

    /// A link opens its tab at the root, then its screen (a student's detail; the fees month is set by the caller).
    /// Returns false when this build has no screen for it, so the caller can say so.
    func open(_ link: DeepLink) -> Bool {
        onTabChosen?()
        selected = link.tab
        paths[link.tab] = []
        switch link {
        case .today, .authCallback: return true
        case .attendance:
            paths[link.tab] = [.attendance]
            return true
        case let .event(id):
            paths[link.tab] = [.event(id)]
            return true
        case let .student(id):
            paths[link.tab] = [.student(id)]
            return true
        case let .school(id):
            paths[link.tab] = [.schoolItem(id)]
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
    /// Teacher reminders, from Settings.
    case reminders
    case student(UUID)
    /// Add a textbook for a student (V2), for a subject or to choose one.
    case textbook(student: UUID, subject: String?)
    /// A student's placement (V2).
    case placement(UUID)
    /// The close of a batch today (V2), from Today's hero.
    case close(UUID)
    /// An artefact of the plan (V2): a sheet, from a plan line or a student's page.
    case artefact(UUID)
    /// Attendance's mark root (D65: under More, and pushed from Today and a batch).
    case attendance
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
    /// Make something, from More and from Today's Create row; its forms, V1's forms and results, and History on the
    /// same stack.
    case make
    case makeForm(MakeKind)
    case aiForm(GenerationKind)
    case aiResult(UUID)
    case aiHistory
    /// Scan register, from More, the Students "+" menu and the empty register.
    case scanRegister
    /// Check a paper, one visit's steps sharing its store (the id): the intro, the pages, the scheme, the marks.
    case checkPaper(UUID)
    case checkPages(UUID)
    case checkScheme(UUID)
    /// The intro's Scheme tile: the Marking scheme screen as a chooser (Phase 15).
    case checkSchemeChooser(UUID)
    case checkResult(UUID)
    /// School (Phase 13): "Check what was read" from a share, a photo, the pasteboard or by hand; an item's page; Ask
    /// parents to forward.
    case schoolRead(ReadSource)
    case schoolItem(UUID)
    case schoolAsk
    /// A student's gap report for an exam (the exam, the student), made when first opened.
    case schoolGapReport(UUID, UUID)
    /// Phase 14: a student's weekly note or can-now-do for a note day, from Today's Read, the held sheet and the sent
    /// log.
    case note(UUID, Day)
    /// A student's sent log, from the page's Messages See all.
    case studentMessages(UUID)
    /// Marks from a photo: the student and the first page, from the page's Marks.
    case readMarks(UUID, ImageUpload)
}
