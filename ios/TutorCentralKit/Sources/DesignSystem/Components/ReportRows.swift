import SwiftUI

/// Reports, fees (P5-Reports-Fees): the name over the class, the amount `numberRow`, the compact chip.
public struct ReportFeeRow: View {
    let name: String
    let className: String
    let amount: String
    let chip: Chip.Kind

    public init(name: String, className: String, amount: String, chip: Chip.Kind) {
        self.name = name
        self.className = className
        self.amount = amount
        self.chip = chip
    }

    public var body: some View {
        ListRow(action: nil) {
            RowTitles(title: name, subtitle: className)
            Text(amount).typeStyle(Tokens.numberRow).monospacedDigit().foregroundStyle(Tokens.text.color)
            Chip(chip, compact: true)
        }
    }
}

/// Reports, attendance (P5-Reports-Attendance): the name over "3 present · 1 absent" (present `ok` 600, absent
/// `overdue` 600 when more than none), the percentage `numberRow` on the right; a student with nothing marked reads
/// "No class, nothing marked" with an en dash in `text3`.
public struct ReportAttendanceRow: View {
    let name: String
    let present: Int?
    let absent: Int?
    let percent: String?

    public init(name: String, present: Int?, absent: Int?, percent: String?) {
        self.name = name
        self.present = present
        self.absent = absent
        self.percent = percent
    }

    public var body: some View {
        ListRow(action: nil) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                counts.typeStyle(Tokens.footnote).monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(percent ?? "–")
                .typeStyle(Tokens.numberRow)
                .monospacedDigit()
                .foregroundStyle((percent == nil ? Tokens.text3 : Tokens.text).color)
        }
    }

    private var counts: Text {
        guard let present, let absent else {
            return Text("No class, nothing marked").foregroundStyle(Tokens.text2.color)
        }
        let presentText = Text("\(present) present").fontWeight(.semibold).foregroundStyle(Tokens.ok.color)
        let absentText = absent > 0
            ? Text("\(absent) absent").fontWeight(.semibold).foregroundStyle(Tokens.overdue.color)
            : Text("\(absent) absent").foregroundStyle(Tokens.text2.color)
        return Text("\(presentText)\(Text(" · ").foregroundStyle(Tokens.text2.color))\(absentText)")
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            ReportFeeRow(name: "Akshita Rao", className: "Class 10 Maths", amount: "₹1,200", chip: .status(.ok, "Paid"))
                .rowDivider()
            ReportAttendanceRow(name: "Hemanth Reddy", present: 1, absent: 2, percent: "33%").rowDivider()
            ReportAttendanceRow(name: "Sahil Verma", present: nil, absent: nil, percent: nil)
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
