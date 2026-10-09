import DesignSystem
import Domain
import Foundation
import SwiftUI

/// The five tabs on iOS 26's own tab bar (components.md, "Tab bar": the system's floating glass bar with the board's
/// symbols), each with its own navigation stack. Today's and Students' roots and the Students screens are passed in;
/// the other three tabs are on the way.
struct TabsView<
    Today: View, Students: View, StudentDetail: View, Classes: View, ClassDetail: View, Settings: View,
    Attendance: View, History: View, StudentMonth: View, Schedule: View, Tasks: View, Fees: View, StudentFees: View,
    Payments: View, Reports: View, Tools: View
>: View {
    @Bindable var state: TabsState
    let toasts: ToastCenter
    let today: () -> Today
    let students: () -> Students
    let studentDetail: (UUID) -> StudentDetail
    let classes: () -> Classes
    let classDetail: (UUID) -> ClassDetail
    /// Settings and the screens on its stack (Account, Delete account, Help).
    let settings: (Route) -> Settings
    let attendance: () -> Attendance
    let history: () -> History
    let studentMonth: (UUID) -> StudentMonth
    let schedule: (UUID?) -> Schedule
    let tasks: () -> Tasks
    let fees: () -> Fees
    let studentFees: (UUID) -> StudentFees
    let payments: () -> Payments
    let reports: () -> Reports
    /// The AI tools' screens (the Assistant, its forms, results and History).
    let tools: (Route) -> Tools

    var body: some View {
        TabView(selection: Binding(get: { state.selected }, set: { state.select($0) })) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) { stack(.today) { today() } }
            Tab("Students", systemImage: "person.2", value: AppTab.students) { stack(.students) { students() } }
            Tab("Fees", systemImage: "indianrupeesign", value: AppTab.fees) { stack(.fees) { fees() } }
            Tab("Attendance", systemImage: "checkmark.circle", value: AppTab.attendance) {
                stack(.attendance) { attendance() }
            }
            Tab("More", systemImage: "ellipsis", value: AppTab.more) {
                stack(.more) { MoreView { state.push($0) } }
            }
        }
        .tint(Tokens.accentText.color)
    }

    /// A pushed screen, by the tab it belongs to.
    @ViewBuilder private func destination(_ route: Route) -> some View {
        switch route {
        case .student, .classes, .classroom, .studentFees: studentsDestination(route)
        case .history, .historyStudent: attendanceDestination(route)
        case .settings, .account, .deleteAccount, .help: settings(route)
        case .payments, .reports: moreDestination(route)
        case .schedule: schedule(nil)
        // A newer link in the same place is a new screen, not the last one's state.
        case let .event(id): schedule(id).id(id)
        case .tasks: tasks()
        case .aiAssistant, .aiForm, .aiResult, .aiHistory, .scanRegister, .checkPaper, .checkPages, .checkScheme,
             .checkResult: tools(route)
        }
    }

    @ViewBuilder private func studentsDestination(_ route: Route) -> some View {
        switch route {
        case let .student(id): studentDetail(id)
        case let .classroom(id): classDetail(id)
        case let .studentFees(id): studentFees(id)
        default: classes()
        }
    }

    @ViewBuilder private func moreDestination(_ route: Route) -> some View {
        if route == .payments {
            payments()
        } else {
            reports()
        }
    }

    @ViewBuilder private func attendanceDestination(_ route: Route) -> some View {
        if case let .historyStudent(id) = route {
            studentMonth(id)
        } else {
            history()
        }
    }

    private func stack(_ tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: Binding(get: { state.paths[tab] ?? [] }, set: { state.paths[tab] = $0 })) {
            root().navigationDestination(for: Route.self, destination: destination)
        }
        // Inside the tab, so a toast sits above the tab bar.
        .overlay(alignment: .bottom) { ToastHost(toasts: toasts) }
    }
}
