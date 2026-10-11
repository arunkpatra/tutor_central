import DesignSystem
import Domain
import SwiftUI

/// An exam's Preparation (P10-School-Item): the header with the quiet Change (Today at the batch's plan), one
/// `PreparationRow` per day to the test, and from the day before the exam the Test tomorrow row.
struct PreparationSection: View {
    let rows: [PreparationRowModel]
    let change: (() -> Void)?
    let open: (PreparationOpen) -> Void
    let testTomorrowLine: String?
    let testTomorrow: (() -> Void)?
    var title = "Preparation"

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title, action: change.map { ("Change", $0) })
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        PreparationRow(
                            day: row.day, date: row.date, title: row.title, line: row.line, mark: row.mark,
                            action: row.opens.map { opens in { open(opens) } }
                        )
                        .rowDivider(row.id != rows.last?.id || testTomorrowLine != nil)
                    }
                    if let testTomorrowLine {
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Text(testTomorrowLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let testTomorrow {
                                Button("Test tomorrow", action: testTomorrow).buttonStyle(.quiet)
                            }
                        }
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    }
                }
            }
        }
    }
}
