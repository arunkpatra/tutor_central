import DesignSystem
import Domain
import SwiftUI

/// Where the gap report leads (AppShell's): Today at the batch's plan.
public struct GapReportActions {
    let openToday: (UUID) -> Void

    public init(openToday: @escaping (UUID) -> Void) {
        self.openToday = openToday
    }
}

/// The gap report (P10-GapReport): "After the mock", the score hero, By skill, The last two days with the quiet Change,
/// Use this plan with its footnote.
public struct GapReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State private var store: GapReportStore
    let actions: GapReportActions
    @State private var topInset: CGFloat = 0

    public init(store: GapReportStore, actions: GapReportActions) {
        _store = State(initialValue: store)
        self.actions = actions
    }

    static let footnote = "Replaces the two days' lines in the plan. Leave it and the plan carries on as it was."

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "After the mock") { dismiss() }
                content
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if store.stage == .ready {
                FooterButton {
                    VStack(spacing: Tokens.rowPaddingDense) {
                        if store.used {
                            // In the plan (P21-GapReport-Used): the exam's job used it when the marks were saved.
                            InThePlanRow()
                        } else {
                            Button("Use this plan") { Task { _ = await store.use() } }
                                .buttonStyle(.primary(.card))
                        }
                        Text(store.used ? store.usedFootnote : Self.footnote).typeStyle(Tokens.footnote)
                            .foregroundStyle(Tokens.text3.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task { await store.load() }
    }

    @ViewBuilder private var content: some View {
        switch store.stage {
        case .loading:
            Card { SkeletonRow() }
        case .making:
            CreatingCard(title: "Reading the marks", line: "The gap report takes a few seconds.", cancel: nil)
        case let .failed(words):
            Card { EmptyRow(symbol: "chart.bar", title: words, line: "Go back to the exam's page.") }
        case .ready:
            ScoreHero(eyebrow: store.eyebrow, score: store.score, of: store.of, line: store.line)
            if let report = store.report {
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader("By skill")
                    Card {
                        VStack(spacing: 0) {
                            ForEach(report.bySkill) { tally in
                                SkillBarRow(
                                    skill: tally.skill,
                                    line: tally.note ?? "",
                                    right: tally.right,
                                    of: tally.of
                                )
                                .rowDivider(tally.id != report.bySkill.last?.id)
                            }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader(
                    "The last two days",
                    action: store.batchID.map { batch in ("Change", { actions.openToday(batch) }) }
                )
                Card {
                    VStack(spacing: 0) {
                        ForEach(store.days) { day in
                            PreparationRow(
                                day: day.day, date: day.date, title: day.title, line: day.line, mark: .none,
                                action: nil
                            )
                            .rowDivider(day.id != store.days.last?.id)
                        }
                    }
                }
            }
        }
    }
}

/// The done row in the primary button's place (P21-GapReport-Used): `surface1` with the `line` border, the tick and "In
/// the plan" in `ok`.
private struct InThePlanRow: View {
    var body: some View {
        Label("In the plan", systemImage: "checkmark")
            .typeStyle(Tokens.buttonStrong)
            .foregroundStyle(Tokens.ok.color)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ButtonSize.card.rawValue)
            .background(
                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous).fill(Tokens.surface1.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                    .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
            )
            .environment(\.buttonIconSize, Tokens.iconSmall)
            .accessibilityElement(children: .combine)
    }
}
