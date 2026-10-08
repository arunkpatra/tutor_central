import DesignSystem
import Domain
import SwiftUI

/// The parent with one tap to call or to WhatsApp (P3-StudentDetail); without a number, the empty row and Add.
struct ParentCard: View {
    let student: Student
    let call: URL?
    let whatsApp: URL?
    let addContact: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let phone = student.parentPhone {
            VStack(spacing: Tokens.rowPaddingDense) {
                HStack(spacing: Tokens.rowPaddingDense) {
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(student.parentName ?? "Parent")
                            .typeStyle(Tokens.rowTitle)
                            .foregroundStyle(Tokens.text.color)
                        Text("Parent").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    }
                    Spacer(minLength: 0)
                    Text(phone.display)
                        .typeStyle(Tokens.subhead)
                        .monospacedDigit()
                        .foregroundStyle(Tokens.text2.color)
                }
                HStack(spacing: Tokens.tileGap) {
                    Button { call.map { openURL($0) } } label: {
                        Label("Call", systemImage: "phone").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.secondary())
                    Button { whatsApp.map { openURL($0) } } label: {
                        Label("WhatsApp", systemImage: "message")
                            .typeStyle(Tokens.buttonStrong)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary())
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
            .padding(.top, Tokens.cardPaddingCompact)
            .padding([.horizontal, .bottom], Tokens.rowPaddingHorizontal)
            .surface(radius: Tokens.radiusCard)
        } else {
            Card {
                HStack {
                    EmptyRow(
                        symbol: "person",
                        title: "No parent contact yet",
                        line: "Add the parent's WhatsApp number to call or message them."
                    )
                    Button("Add", action: addContact)
                        .buttonStyle(.quiet)
                        .padding(.trailing, Tokens.rowPaddingHorizontal)
                }
            }
        }
    }
}

/// This month's fee: the month, how it stands, the amount and its chip; See all leads to the ledger (later).
struct MonthFeeCard: View {
    let store: StudentDetailStore
    let seeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Fees", action: ("See all", seeAll))
            HStack(spacing: Tokens.rowPaddingDense) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(store.monthTitle).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(store.monthLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let amount = store.monthAmount {
                    Text(amount).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
                }
                if let mark = store.monthMark {
                    if let tone = mark.tone {
                        Chip(.status(tone, mark.text, symbol: tone == .ok ? "checkmark" : "clock"), compact: true)
                    } else {
                        Chip(.neutral(mark.text), compact: true)
                    }
                }
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .accessibilityElement(children: .combine)
            .surface(radius: Tokens.radiusCard)
        }
    }
}

/// This month's attendance (P4-StudentDetail-Attendance): the month over its bar and line, the percent on the right;
/// See all opens the student's month. Nothing marked: the empty row.
struct AttendanceCard: View {
    let store: StudentDetailStore
    let seeAll: () -> Void

    private var emptyLine: String {
        "Mark \(store.student?.firstName ?? "the student")'s class from the Attendance tab to see this month here."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Attendance", action: ("See all", seeAll))
            Card {
                if let card = store.attendanceCard {
                    HStack(spacing: Tokens.rowPaddingDense) {
                        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                            Text(card.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                            ProgressBar(fraction: card.fraction)
                            Text(card.line).typeStyle(Tokens.footnote).monospacedDigit()
                                .foregroundStyle(Tokens.text2.color)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(card.percent).typeStyle(Tokens.numberRow).monospacedDigit()
                            .foregroundStyle(Tokens.text.color)
                    }
                    .padding(.vertical, Tokens.rowPaddingDense)
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .accessibilityElement(children: .combine)
                } else {
                    EmptyRow(symbol: "checkmark.circle", title: "Nothing marked yet", line: emptyLine)
                }
            }
        }
        .task { await store.loadAttendance() }
    }
}
