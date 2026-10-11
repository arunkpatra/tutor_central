import DesignSystem
import Domain
import SwiftUI

/// The exam's last days (P10-School-Exam-LastDays): Today (the mock and Mark from a photo), Marked (each student with
/// Gap report), The last two days with the Test tomorrow row.
struct LastDaysSections: View {
    let model: LastDaysModel
    let openMock: (UUID) -> Void
    let mark: () -> Void
    let openGapReport: (UUID) -> Void
    let testTomorrowLine: String?
    let testTomorrow: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            todaySection
            markedSection
            PreparationSection(
                rows: model.lastDays, change: nil, open: { _ in }, testTomorrowLine: testTomorrowLine,
                testTomorrow: testTomorrow, title: "The last two days"
            )
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(model.todayTitle)
            Card {
                VStack(spacing: 0) {
                    if let mock = model.mockID {
                        ToolRow(symbol: "doc.text", title: model.mockTitle, line: model.mockLine, ready: true) {
                            openMock(mock)
                        }
                        .rowDivider(true)
                    } else {
                        HStack(spacing: Tokens.rowPaddingDense) {
                            IconTile(symbol: "doc.text")
                            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                Text(model.mockTitle).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                Text(model.mockLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    }
                    if model.mockID != nil {
                        ToolRow(
                            symbol: "camera",
                            title: "Mark from a photo",
                            line: LastDaysModel.markLine,
                            action: mark
                        )
                    }
                }
            }
        }
    }

    private var markedSection: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Marked")
            Card {
                VStack(spacing: 0) {
                    ForEach(model.marked) { row in
                        HStack(spacing: Tokens.rowPaddingDense) {
                            Avatar(initials: row.initials, size: WhoSection.avatar)
                            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                Text(row.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                Text([row.line, row.consentLine].compactMap(\.self).joined(separator: " · "))
                                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if row.canReport {
                                Button("Gap report") { openGapReport(row.id) }.buttonStyle(.quiet(emphasised: true))
                            }
                        }
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .rowDivider(row.id != model.marked.last?.id)
                    }
                }
            }
        }
    }
}
