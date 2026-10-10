import DesignSystem
import Domain
import SwiftUI

/// The More tab's root (P10-More, dark and light): Organise (Schedule, Attendance, Tasks, Batches, Reports), Make (Make
/// something, Check a paper, Scan register) and App (Settings, Account, Help). Its rows are navigation, so the root is
/// AppShell's. Make something opens the AI Assistant until Phase 15 builds Make (the 10.1 note).
struct MoreView: View {
    let open: (Route) -> Void
    @State private var topInset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                Text("More")
                    .typeStyle(Tokens.display)
                    .singleLineTitle()
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                group("Organise") {
                    SettingRow(symbol: "calendar", label: "Schedule", action: { open(.schedule) }).rowDivider()
                    SettingRow(symbol: "checkmark.circle", label: "Attendance", action: { open(.attendance) })
                        .rowDivider()
                    SettingRow(symbol: "checklist", label: "Tasks", action: { open(.tasks) }).rowDivider()
                    SettingRow(symbol: "book.closed", label: "Batches", action: { open(.classes) }).rowDivider()
                    SettingRow(symbol: "chart.bar", label: "Reports", action: { open(.reports) })
                }
                group("Make") {
                    SettingRow(symbol: "sparkles", label: "Make something", action: { open(.aiAssistant) })
                        .rowDivider()
                    SettingRow(
                        symbol: "doc.text.magnifyingglass", label: "Check a paper",
                        action: { open(.checkPaper(UUID())) }
                    )
                    .rowDivider()
                    SettingRow(symbol: "doc.viewfinder", label: "Scan register", action: { open(.scanRegister) })
                }
                group("App") {
                    SettingRow(symbol: "gearshape", label: "Settings", action: { open(.settings) }).rowDivider()
                    SettingRow(symbol: "person.crop.circle", label: "Account", action: { open(.account) }).rowDivider()
                    SettingRow(symbol: "questionmark.circle", label: "Help", action: { open(.help) })
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
