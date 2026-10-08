import DesignSystem
import Domain
import SwiftUI

/// P5-MarkPaid: the method (UPI, Cash, Other), the day (today, or any earlier day through the system's date picker),
/// who is offered the receipt, "Waive this fee instead", and Mark ₹1,000 paid. The write waits for the server.
struct MarkPaidSheet: View {
    let subject: FeeSubject
    let today: Day
    let receiptNote: String?
    let writing: Bool
    let markPaid: (MonthFee.PaidMethod, Day) -> Void
    let waive: () -> Void
    let close: () -> Void
    @State private var method: MonthFee.PaidMethod = .upi
    @State private var day: Day?
    @State private var picksDay = false
    /// The board's sheet starts 357 pt down an 852 pt screen.
    static let boardFraction = 0.62

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Mark paid", cancel: ("Cancel", close))
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                FeeSubjectLine(subject: subject)
                SheetField(label: "Paid by") {
                    Segmented(options: [(.upi, "UPI"), (.cash, "Cash"), (.other, "Other")], selection: $method)
                }
                SheetField(label: "Paid on") {
                    Button { picksDay = true } label: {
                        TileRow(label: "Day", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                            PickerValue(dayText)
                        }
                        .contentShape(.rect)
                    }
                    .pressable()
                    .accessibilityValue(dayText)
                    .popover(isPresented: $picksDay) {
                        DatePicker(
                            "Paid on",
                            selection: dayBinding,
                            in: ...today.date(in: DayHeading.india),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .calendarPopover(timeZone: DayHeading.india.timeZone)
                    }
                }
                if let receiptNote {
                    Text(receiptNote).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: Tokens.rowPaddingDense) {
                if subject.invoice.status != .waived {
                    Button("Waive this fee instead", action: waive).buttonStyle(.quiet)
                }
                Button { markPaid(method, chosenDay) } label: {
                    Label("Mark \(subject.invoice.amount.formatted) paid", systemImage: "checkmark")
                }
                .buttonStyle(.primary(.sheet, loading: writing))
                .disabled(writing)
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .presentationDetents([.fraction(Self.boardFraction), .large])
    }

    private var chosenDay: Day {
        day ?? today
    }

    /// "Today, 7 Oct" or "Mon 5 Oct".
    private var dayText: String {
        chosenDay == today ? "Today, \(today.shortText)" : chosenDay.shortWeekdayText
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { chosenDay.date(in: DayHeading.india) },
            set: { date in
                picksDay = false
                day = Day(date, calendar: DayHeading.india)
            }
        )
    }
}
