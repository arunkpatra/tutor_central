import DesignSystem
import Domain
import SwiftUI

/// The More tab's root (P4-More, dark and light): Organise (Schedule, Tasks, Classes; Reports later), Create (the AI
/// tools, later) and App (Settings; Account and Help later). Its rows are navigation, so the root is AppShell's.
struct MoreView: View {
    let open: (Route) -> Void
    @State private var topInset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                Text("More")
                    .typeStyle(Tokens.display)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                group("Organise") {
                    SettingRow(symbol: "calendar", label: "Schedule", action: { open(.schedule) }).rowDivider()
                    SettingRow(symbol: "checkmark.circle", label: "Tasks", action: { open(.tasks) }).rowDivider()
                    SettingRow(symbol: "book.closed", label: "Classes", action: { open(.classes) }).rowDivider()
                    LaterRow(symbol: "chart.bar", label: "Reports", phase: "Phase 5")
                }
                group("Create") {
                    LaterRow(symbol: "sparkles", label: "AI Assistant", phase: "Phase 6").rowDivider()
                    LaterRow(symbol: "doc.text.magnifyingglass", label: "Check a paper", phase: "Phase 6").rowDivider()
                    LaterRow(symbol: "doc.viewfinder", label: "Scan register", phase: "Phase 6")
                }
                group("App") {
                    SettingRow(symbol: "gearshape", label: "Settings", action: { open(.settings) }).rowDivider()
                    LaterRow(symbol: "person.crop.circle", label: "Account", phase: "Phase 7").rowDivider()
                    LaterRow(symbol: "questionmark.circle", label: "Help", phase: "Phase 7")
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func group(_ title: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card {
                VStack(spacing: 0) { rows() }
            }
        }
    }
}
