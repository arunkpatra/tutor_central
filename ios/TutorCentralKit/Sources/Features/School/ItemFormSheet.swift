import DesignSystem
import Domain
import SwiftUI

/// The item's sheet (P10-School-Confirm-Edit, P10-School-Item-Edit): Cancel, "Item", Save; Kind, Title, For (the For
/// sheet), Subject, Date (and To for a holiday), a kept exam's Preparation (P14-School-Item-Window), Portions with the
/// 500 counter, Remove this item.
public struct ItemFormSheet: View {
    @Bindable var store: ItemFormStore
    let onSave: (SchoolItemDraft) -> Void
    let onRemove: (() -> Void)?
    let onClose: () -> Void
    @State private var choosingFor = false
    @State private var picksDate = false
    @State private var picksEnd = false
    @State private var picksWindow = false

    public init(
        store: ItemFormStore, onSave: @escaping (SchoolItemDraft) -> Void, onRemove: (() -> Void)?,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.onSave = onSave
        self.onRemove = onRemove
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(
                title: "Item", cancel: ("Cancel", onClose),
                save: .init("Save", enabled: store.canSave) { onSave(store.draft()) }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                    ChipRow(
                        label: "Kind", options: SchoolItemKind.allCases.map { ($0, $0.title) }, selection: $store.kind
                    )
                    TextWell(
                        label: "Title",
                        text: $store.title,
                        placeholder: "Science unit test 3",
                        capitalisation: .sentences
                    )
                    PickerField(
                        label: "For",
                        value: store.audience == nil ? nil : store.forValue,
                        placeholder: "Choose",
                        helper: store.forNote
                    ) { choosingFor = true }
                    subject
                    dates
                    if store.showsWindow {
                        preparation
                    }
                    NotesWell(
                        label: "Portions", text: $store.portions, placeholder: "Chapters, pages or topics",
                        limit: SchoolItemRules.portionsLimit, optional: true
                    )
                    if let onRemove {
                        Button(action: onRemove) {
                            Label("Remove this item", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.destructive(.card))
                        .environment(\.buttonIconSize, Tokens.iconSmall)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .sheet(isPresented: $choosingFor) {
            ForSheet(store: store) { choosingFor = false }
        }
        .modifier(SheetToasts())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var subject: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            TextWell(
                label: "Subject", text: Binding(get: { store.subject ?? "" }, set: { store.subject = $0 }),
                placeholder: "Science", optional: store.kind != .exam
            )
            FlowLayout(spacing: Tokens.inline) {
                ForEach(Subject.common, id: \.self) { name in
                    FilterChip(name, isOn: store.subject == name) { store.subject = name }
                }
            }
        }
    }

    /// The exam's window: the system wheel of 7, 10, 14 and 21 days in a popover (U43).
    private var preparation: some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            PickerTile(label: "Preparation", value: store.windowTitle) { picksWindow = true }
                .popover(isPresented: $picksWindow) {
                    WheelPopover(
                        eyebrow: "Preparation", values: store.windowChoices, selection: $store.windowDays
                    ) { "\($0) days before" }
                }
            FieldHelper("Revision starts this many days before the test. 14 unless you change it.")
        }
    }

    @ViewBuilder private var dates: some View {
        let calendar = DayHeading.india
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(SchoolWords.dateLabel(store.kind)).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            HStack(spacing: Tokens.inline) {
                PickerTile(label: store.kind == .holiday ? "From" : "Day", value: store.date?.fullText ?? "Choose") {
                    store.openDay()
                    picksDate = true
                }
                .popover(isPresented: $picksDate) {
                    DatePicker("Day", selection: dayBinding(\.date, calendar: calendar), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .calendarPopover(timeZone: calendar.timeZone)
                }
                if store.kind == .holiday {
                    PickerTile(label: "To", value: store.endDate?.fullText ?? "Choose") {
                        store.openEndDay()
                        picksEnd = true
                    }
                    .popover(isPresented: $picksEnd) {
                        DatePicker(
                            "To",
                            selection: dayBinding(\.endDate, calendar: calendar),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .calendarPopover(timeZone: calendar.timeZone)
                    }
                }
            }
        }
    }

    private func dayBinding(
        _ path: ReferenceWritableKeyPath<ItemFormStore, Day?>,
        calendar: Calendar
    ) -> Binding<Date> {
        Binding(
            get: { (store[keyPath: path] ?? store.today).date(in: calendar) },
            set: { store[keyPath: path] = Day($0, calendar: calendar) }
        )
    }
}

/// The For sheet: each school's classes with their students, every class at the school, then one student.
struct ForSheet: View {
    @Bindable var store: ItemFormStore
    let close: () -> Void

    var body: some View {
        let options = store.forOptions
        let groups = options.reduce(into: [String]()) { names, option in
            if !names.contains(option.group) {
                names.append(option.group)
            }
        }
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "For", cancel: ("Done", close))
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    ForEach(groups, id: \.self) { group in
                        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                            SectionHeader(group.isEmpty ? "One student" : group)
                            Card {
                                VStack(spacing: 0) {
                                    let rows = options.filter { $0.group == group }
                                    ForEach(rows) { option in
                                        ChoiceRow(
                                            symbol: symbol(option.audience), title: option.title, line: option.line,
                                            chosen: store.audience == option.audience
                                        ) {
                                            store.audience = option.audience
                                            close()
                                        }
                                        .rowDivider(option.id != rows.last?.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private func symbol(_ audience: ItemAudience) -> String {
        switch audience {
        case .schoolClass: "person.3"
        case .school: "building.columns"
        case .student: "person"
        }
    }
}
