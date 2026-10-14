import DesignSystem
import Domain
import SwiftUI

/// The exam's last days (P10-School-Exam-LastDays; the exam's job, P21-Exam-*): Today (the mock being made, not made
/// with Try again, or ready, and Mark from a photo), Marked (each student with Gap report, or Working while the job
/// works their report out), The last two days with the Changed chip, Change and the Test tomorrow row.
struct LastDaysSections: View {
    let model: LastDaysModel
    let openMock: (UUID) -> Void
    let mark: () -> Void
    let openGapReport: (UUID) -> Void
    let testTomorrowLine: String?
    let testTomorrow: (() -> Void)?
    var tryAgain: (() -> Void)?
    var change: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            todaySection
            markedSection
            PreparationSection(
                rows: model.lastDays, change: model.changed ? change : nil, open: { _ in },
                testTomorrowLine: testTomorrowLine, testTomorrow: testTomorrow, title: "The last two days"
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
                        mockWaitRow
                            .rowDivider([.making, .failed].contains(model.mockState))
                    }
                    if model.mockID != nil {
                        ToolRow(
                            symbol: "camera",
                            title: "Mark from a photo",
                            line: LastDaysModel.markLine,
                            action: mark
                        )
                    } else if [.making, .failed].contains(model.mockState) {
                        // Mark from a photo waits for the mock (P21-Exam-MockMaking, -MockFailed).
                        HStack(spacing: Tokens.rowPaddingDense) {
                            IconTile(symbol: "camera")
                            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                Text("Mark from a photo").typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                Text(LastDaysModel.markWaitsLine).typeStyle(Tokens.footnote)
                                    .foregroundStyle(Tokens.text2.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                        .opacity(Tokens.opacityDisabled)
                        .accessibilityElement(children: .combine)
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
                            AdaptiveRow {
                                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                    Text(row.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                    Text([row.line, row.consentLine].compactMap(\.self).joined(separator: " · "))
                                        .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                if row.working {
                                    WorkingTrail()
                                } else if row.canReport {
                                    Button("Gap report") { openGapReport(row.id) }
                                        .buttonStyle(.quiet(emphasised: true))
                                }
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

    /// The mock's row before it is ready: made with the mock day's plan; Being made this morning; or not made, with Try
    /// again in place (U33's row for what could not be made).
    private var mockWaitRow: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            IconTile(symbol: "doc.text")
            AdaptiveRow {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(model.mockTitle).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(model.mockLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if model.mockState == .making {
                    Chip(.working("Being made"))
                }
                // Try again trails the words (P21-Exam-MockFailed), as Gap report does on a Marked row.
                if model.mockState == .failed, let tryAgain {
                    Button("Try again", action: tryAgain).buttonStyle(.quiet(emphasised: true))
                }
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}
