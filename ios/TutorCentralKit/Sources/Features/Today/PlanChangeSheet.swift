import DesignSystem
import Domain
import SwiftUI

/// Change the plan (P10-Today-Plan-Change), at the content's height: the group count, each group's subject today, Keep
/// this for the weekday, Make the plan again, Use this plan. Nothing here is carried to another day unless kept.
struct PlanChangeSheet: View {
    let store: PlanStore
    let weekday: Weekday
    let onClose: () -> Void
    @State private var choices: PlanChoices
    @State private var rows: [ChangeRow] = []
    @State private var keeps = false
    @State private var working = false

    init(store: PlanStore, weekday: Weekday, onClose: @escaping () -> Void) {
        self.store = store
        self.weekday = weekday
        self.onClose = onClose
        _choices = State(initialValue: store.changeChoices)
    }

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: "Change the plan", cancel: ("Cancel", onClose))
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    Menu {
                        ForEach(1 ... PlanRules.maxGroups, id: \.self) { count in
                            Button("\(count)") { choose(groups: count) }
                        }
                    } label: {
                        PickerTileLabel(label: "Groups", value: "\(choices.groups ?? rows.count)", placeholder: "")
                    }
                    FieldHelper("One to three, by level. One group puts everyone together.")
                }
                ForEach(rows) { row in
                    Menu {
                        ForEach(row.offered, id: \.self) { subject in
                            Button(subject) { choices.subjects[row.number] = subject }
                        }
                    } label: {
                        PickerTileLabel(
                            label: row.title, value: choices.subjects[row.number] ?? row.subject, placeholder: ""
                        )
                    }
                }
                SettingRow(
                    label: "Keep this for \(weekday.name)s",
                    line: "The same subjects next \(weekday.name); the groups still follow the record"
                ) { Switch(isOn: $keeps, label: "Keep this for \(weekday.name)s") }
                Button("Make the plan again") { Task { await apply(nil) } }
                    .buttonStyle(.quiet(emphasised: true))
                    .disabled(working)
                Button("Use this plan") { Task { await apply(choices) } }
                    .buttonStyle(.primary(.form, loading: working))
                    .disabled(working)
                    .padding(.top, Tokens.sectionGap)
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
        .task {
            await store.readSubjects()
            rows = await store.preview(choices)
        }
    }

    private func choose(groups count: Int) {
        choices.groups = count
        choices.subjects = [:]
        Task { rows = await store.preview(choices) }
    }

    /// Today's plan made again, with the sheet's choices or none; kept for the weekday when asked.
    private func apply(_ chosen: PlanChoices?) async {
        working = true
        if keeps, let chosen {
            await store.keep(choices: chosen, for: weekday)
        }
        onClose()
        await store.useToday(choices: chosen)
        working = false
    }
}
