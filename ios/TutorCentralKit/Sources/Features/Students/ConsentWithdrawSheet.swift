import DesignSystem
import Domain
import SwiftUI

/// Parent withdrew (P18-Consent-Withdraw): the record sheet's frame with how, the day (the agreement's day to today), a
/// box of what stops at once, the footnote, and Record the withdrawal. Offline it is refused as every consent write is
/// (D39) and the sheet stays.
struct ConsentWithdrawSheet: View {
    @Bindable var store: ConsentStore
    let close: () -> Void
    @State private var saving = false
    @State private var pickingDay = false

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: "Parent withdrew", cancel: ("Cancel", close))
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                HStack(spacing: Tokens.cardPaddingCompact) {
                    Avatar(name: store.student?.name ?? "", size: MessageSheet.avatarSize)
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(store.withdrawTitle).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                        Text(store.sheetLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                }
                .accessibilityElement(children: .combine)
                ChipRow(
                    label: "How", options: ConsentMethod.allCases.map { ($0, $0.title) },
                    selection: $store.withdrawSheet.how
                )
                PickerTile(label: "Withdrew on", value: store.withdrewOnText) { pickingDay = true }
                    .popover(isPresented: $pickingDay) {
                        DatePicker("Withdrew on", selection: dayBinding, in: range, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .calendarPopover(timeZone: DayHeading.india.timeZone)
                    }
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    Text("From now, at once").typeStyle(Tokens.footnoteStrong).foregroundStyle(Tokens.text.color)
                    Text(store.withdrawStops)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Tokens.rowPaddingDense)
                .padding(.horizontal, Tokens.cardPaddingCompact)
                .background(Tokens.surface2.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                .accessibilityElement(children: .combine)
                FieldHelper(store.withdrawFootnote)
                Button("Record the withdrawal") { save() }
                    .buttonStyle(.destructive(.sheet, loading: saving))
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var range: ClosedRange<Date> {
        let days = store.withdrawDays
        return days.lowerBound.date(in: DayHeading.india) ... days.upperBound.date(in: DayHeading.india)
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { store.withdrawSheet.withdrewOn.date(in: DayHeading.india) },
            set: {
                store.withdrawSheet.withdrewOn = Day($0, calendar: DayHeading.india)
                pickingDay = false
            }
        )
    }

    private func save() {
        guard !saving else { return }
        saving = true
        Task {
            if await store.withdraw() {
                close()
            }
            saving = false
        }
    }
}
