import DesignSystem
import Domain
import SwiftUI

/// "Today's plan" for one batch (P10-Today-Plan and its states): the header with the quiet Change, a card per group,
/// the brief's row after its group, the planning card while the plan is made; nothing while there is no plan or the
/// network is away with no copy (plan decision 14).
struct PlanSection: View {
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    let store: PlanStore
    let title: String
    let open: (PlanOpen) -> Void
    let change: () -> Void
    /// A board state's open menu (P10-Today-Plan-StudentMenu): the student whose line shows it.
    let menuFor: UUID?

    var body: some View {
        content.onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
    }

    @ViewBuilder private var content: some View {
        switch store.state {
        case .none, .offline:
            EmptyView()
        case let .failed(words):
            section(change: nil) { failed(words) }
        case .planning(nil):
            section(change: nil) {
                CreatingCard(title: "Planning today's class", line: Self.planningLine, cancel: store.cancel)
            }
        case .planning, .made:
            section(change: change) { cards }
        }
    }

    /// The scroll target of a batch's group card.
    static func groupID(_ batch: UUID, _ group: Int) -> String {
        "plan-\(batch.uuidString)-\(group)"
    }

    static let planningLine = "A few seconds. The groups first, then each group's set, sheet and checks. You can start "
        + "the class meanwhile; the lines fill in as they come."

    private func section(change: (() -> Void)?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title, action: change.map { ("Change", $0) })
            content()
        }
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            ForEach(store.groups) { group in
                GroupCardView(group: group, groups: store.groups.map(\.id), store: store, open: open, menuFor: menuFor)
                    .id(PlanSection.groupID(store.classID, group.id))
                ForEach(store.briefRows.filter { $0.afterGroup == group.id }) { brief in
                    Card {
                        ToolRow(symbol: "book", title: brief.title, line: brief.line) {
                            if let id = brief.artefactID {
                                open(.artefact(id))
                            }
                        }
                    }
                }
            }
        }
    }

    private func failed(_ words: String) -> some View {
        HStack {
            Text(words).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Try Again") { Task { await store.load() } }.buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}

/// A group's card: the head with its marks, then a line per student with its menu on a long press.
struct GroupCardView: View {
    let group: GroupCardModel
    let groups: [Int]
    let store: PlanStore
    let open: (PlanOpen) -> Void
    let menuFor: UUID?

    var body: some View {
        Card {
            VStack(spacing: 0) {
                GroupHead(title: group.title, line: group.line, marks: group.marks).rowDivider()
                ForEach(group.lines) { line in
                    PlanLineRow(
                        initials: line.initials, name: line.name, status: (line.status, line.statusKind),
                        note: line.note, teachLine: line.teach, rest: line.rest
                    ) { press(line) }
                        .contextMenu { LineMenu.rows(groups: groups, current: group.id, actions: actions(line)) }
                        .popover(isPresented: .constant(menuFor == line.id), arrowEdge: .top) {
                            LineMenuCard(groups: groups, current: group.id, actions: actions(line))
                                .presentationCompactAdaptation(.popover)
                        }
                        .rowDivider(line.id != group.lines.last?.id)
                }
            }
        }
    }

    /// A line opens its homework sheet (the board's "sheet 1"), else its set.
    private func press(_ line: PlanLineModel) {
        let target = line.items.first { $0.kind == .homework && $0.artefactID != nil }
            ?? line.items.first { $0.kind == .practise && $0.artefactID != nil }
        if let target, let opened = store.open(line: target) {
            open(opened)
        }
    }

    private func actions(_ line: PlanLineModel) -> LineMenu.Actions {
        LineMenu.Actions(
            move: { group in Task { await store.move(student: line.id, to: group) } },
            skipCheck: { Task { await store.skipCheck(student: line.id) } },
            skipHomework: { Task { await store.skipHomework(student: line.id) } },
            leaveOut: { Task { await store.leaveOut(student: line.id) } }
        )
    }
}

/// The line menu drawn as the Phase 3 menu (260 wide) for the board state; real use is the system's context menu.
struct LineMenuCard: View {
    let groups: [Int]
    let current: Int
    let actions: LineMenu.Actions
    static var width: CGFloat {
        260
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(LineMenu.moveTargets(groups: groups, current: current), id: \.self) { group in
                row("Move to Group \(group)", symbol: "arrow.right") { actions.move(group) }.rowDivider(glass: true)
            }
            row("Skip the check today", symbol: "minus", action: actions.skipCheck).rowDivider(glass: true)
            row("Skip homework today", symbol: "minus", action: actions.skipHomework).rowDivider(glass: true)
            row("Leave out today", symbol: "xmark", action: actions.leaveOut)
        }
        .frame(width: Self.width)
    }

    private func row(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                Spacer(minLength: 0)
                Image(systemName: symbol).accessibilityHidden(true).font(.system(size: Tokens.iconButton))
                    .foregroundStyle(Tokens.text2.color)
            }
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(height: Well<EmptyView>.height)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
