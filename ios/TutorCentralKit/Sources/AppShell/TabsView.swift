import DesignSystem
import Domain
import Foundation
import SwiftUI

/// The five tabs on iOS 26's own tab bar (components.md, "Tab bar": the system's floating glass bar with the board's
/// symbols), each with its own navigation stack. Today's and Students' roots and the Students screens are passed in;
/// the other three tabs are on the way.
struct TabsView<
    Today: View, Students: View, StudentDetail: View, Classes: View, ClassDetail: View, Settings: View,
    Attendance: View, History: View, StudentMonth: View
>: View {
    @Bindable var state: TabsState
    let build: String
    let toasts: ToastCenter
    let today: () -> Today
    let students: () -> Students
    let studentDetail: (UUID) -> StudentDetail
    let classes: () -> Classes
    let classDetail: (UUID) -> ClassDetail
    let settings: () -> Settings
    let attendance: () -> Attendance
    let history: () -> History
    let studentMonth: (UUID) -> StudentMonth

    var body: some View {
        TabView(selection: Binding(get: { state.selected }, set: { state.select($0) })) {
            Tab("Today", systemImage: "sun.max", value: AppTab.today) { stack(.today) { today() } }
            Tab("Students", systemImage: "person.2", value: AppTab.students) { stack(.students) { students() } }
            Tab("Fees", systemImage: "indianrupeesign", value: AppTab.fees) { stack(.fees) { later(.fees) } }
            Tab("Attendance", systemImage: "checkmark.circle", value: AppTab.attendance) {
                stack(.attendance) { attendance() }
            }
            Tab("More", systemImage: "ellipsis", value: AppTab.more) { stack(.more) { later(.more) } }
        }
        .tint(Tokens.accentText.color)
    }

    private func stack(_ tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: Binding(get: { state.paths[tab] ?? [] }, set: { state.paths[tab] = $0 })) {
            root()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case let .later(place): LaterView(place: place, build: build)
                    case .settings: settings()
                    case let .student(id): studentDetail(id)
                    case .classes: classes()
                    case let .classroom(id): classDetail(id)
                    case .history: history()
                    case let .historyStudent(id): studentMonth(id)
                    }
                }
        }
        // Inside the tab, so a toast sits above the tab bar.
        .overlay(alignment: .bottom) { ToastHost(toasts: toasts) }
    }

    private func later(_ tab: AppTab) -> some View {
        LaterView(place: .tab(tab), build: build)
    }
}
