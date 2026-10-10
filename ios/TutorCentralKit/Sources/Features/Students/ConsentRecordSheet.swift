import DesignSystem
import Domain
import SwiftUI

/// Parent agreed (P10-Consent-Record): how, the day (today or earlier), the parent's number, Record it; Remove when a
/// record exists (plan decision 13).
struct ConsentRecordSheet: View {
    @Bindable var store: ConsentStore
    let close: () -> Void
    @State private var saving = false
    @State private var pickingDay = false

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: "Parent agreed", cancel: ("Cancel", close))
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                HStack(spacing: Tokens.cardPaddingCompact) {
                    Avatar(name: store.student?.name ?? "", size: MessageSheet.avatarSize)
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(store.sheetTitle).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                        Text(store.sheetLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                }
                .accessibilityElement(children: .combine)
                ChipRow(
                    label: "How", options: ConsentMethod.allCases.map { ($0, $0.title) }, selection: $store.sheet.how
                )
                PickerTile(label: "Agreed on", value: store.agreedOnText) { pickingDay = true }
                    .popover(isPresented: $pickingDay) {
                        DatePicker("Agreed on", selection: dayBinding, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .calendarPopover(timeZone: DayHeading.india.timeZone)
                    }
                PhoneWell(label: "Parent's number", digits: $store.sheet.digits)
                FieldHelper(store.sheetFootnote)
                Button {
                    save { await store.record() }
                } label: {
                    Label("Record it", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary(.card, loading: saving))
                .disabled(!store.sheet.canRecord)
                if case .agreed = store.state {
                    Button("Remove") { save { await store.remove() } }.buttonStyle(.destructive(.form))
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { store.sheet.agreedOn.date(in: DayHeading.india) },
            set: {
                store.sheet.agreedOn = Day($0, calendar: DayHeading.india)
                pickingDay = false
            }
        )
    }

    private func save(_ write: @escaping () async -> Bool) {
        guard !saving else { return }
        saving = true
        Keyboard.dismiss()
        Task {
            if await write() {
                close()
            }
            saving = false
        }
    }
}
