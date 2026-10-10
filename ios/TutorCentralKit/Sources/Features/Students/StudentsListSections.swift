import DesignSystem
import Domain
import SwiftUI

/// The search field and, while not searching, the filter chips running to the screen edge (shown once a class or an
/// archived student exists).
struct SearchAndFilters: View {
    @Bindable var store: RegisterStore
    @Binding var searching: Bool
    let showsFocus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
            SearchWell(
                text: $store.search,
                placeholder: "Search by name or phone",
                isSearching: $searching,
                showsFocus: showsFocus
            )
            if store.showsFilters, !searching {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Tokens.inline) {
                        chip("All", .all)
                        ForEach(store.activeClasses) { classroom in
                            chip(classroom.name, .classroom(classroom.id))
                        }
                        chip("No batch", .unassigned)
                        if store.students.contains(where: \.isArchived) {
                            chip("Archived", .archived)
                        }
                    }
                    .padding(.horizontal, Tokens.pageSide)
                }
                .padding(.horizontal, -Tokens.pageSide)
            }
        }
    }

    private func chip(_ label: String, _ filter: StudentFilter) -> some View {
        FilterChip(label, isOn: store.filter == filter) { store.filter = filter }
    }
}

/// One compact row that opens the batches list: the icon tile, "Batches", the batch names, the count.
struct ClassesRow: View {
    let classes: [Classroom]
    let open: () -> Void

    var body: some View {
        ClassRow(name: "Batches", summary: classes.map(\.name).joined(separator: " · "), members: classes.count) {
            open()
        }
        .surface(radius: Tokens.radiusTile)
    }
}

/// The count line with the sort, then the list card: skeleton rows while nothing is cached, the stale pattern while
/// refreshing, the error line with Retry when a refresh failed; while searching, the line under the list.
struct RegisterList: View {
    @Bindable var store: RegisterStore
    let searching: Bool
    let openStudent: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            header
            if let error = store.error {
                ErrorLine(error) { Task { await store.refresh() } }
            }
            if store.loading {
                Card {
                    VStack(spacing: 0) {
                        SkeletonRow().rowDivider()
                        SkeletonRow(widths: (0.4, 0.65)).rowDivider()
                        SkeletonRow()
                    }
                }
            } else if store.visible.isEmpty, store.isSearching {
                Card {
                    EmptyState(
                        symbol: "magnifyingglass",
                        title: "No one matches",
                        line: "Try another part of the name or the number."
                    )
                }
            } else if !store.visible.isEmpty {
                Card { rows }.opacity(store.refreshing ? Tokens.opacityStale : 1)
            }
            if searching {
                Text("Matches names and phone numbers, in every batch and the archive.")
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
            Text(store.countLine)
                .typeStyle(Tokens.headline)
                .foregroundStyle(Tokens.text.color)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)
            if store.refreshing {
                RefreshSpinner()
            }
            Spacer()
            if !searching {
                Menu {
                    Picker("Sort by", selection: $store.sort) {
                        ForEach(StudentSort.allCases, id: \.self) { sort in
                            Text(sort.label).tag(sort)
                        }
                    }
                } label: {
                    HStack(spacing: Tokens.rowGapInner * 2) {
                        Text(store.sort.label).typeStyle(Tokens.buttonSecondary)
                        Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                            .font(.system(size: Tokens.iconInline))
                    }
                    .foregroundStyle(Tokens.accentText.color)
                }
                .accessibilityLabel("Sort by \(store.sort.label)")
            }
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }

    private var rows: some View {
        let shown = store.visible
        return VStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, student in
                StudentRow(
                    initials: student.initials,
                    name: student.name,
                    nameMatch: StudentQuery.matchRange(in: student.name, search: store.search),
                    detail: store.rowDetail(for: student),
                    fee: student.fee(in: store.classroom(student.classID))?.formatted,
                    status: student.feeMark.map(Self.status),
                    lead: (student.trackStatus.title, student.trackStatus.kind)
                ) { openStudent(student.id) }
                    .rowDivider(index < shown.count - 1)
            }
        }
    }

    static func status(_ mark: FeeMark) -> (tone: StatusTone?, text: String) {
        switch mark {
        case .paid: (.ok, mark.text)
        case .due: (.due, mark.text)
        case .waived: (nil, mark.text)
        }
    }
}

/// Under a class's filtered list: its meeting summary and fee in footnote text3, and a quiet Open class.
struct ClassFooter: View {
    let classroom: Classroom
    let open: () -> Void

    var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            Spacer(minLength: 0)
            Button("Open batch", action: open).buttonStyle(.quiet).fixedSize()
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }

    private var line: String {
        [classroom.meetingSummary, classroom.monthlyFee.map { "\($0.formatted) a month" }]
            .compactMap(\.self)
            .joined(separator: " · ")
    }
}

/// The register's first screen (P3-Students-Empty): what will appear, and the two ways to start.
struct NoStudentsCard: View {
    let addStudent: () -> Void
    let scanRegister: () -> Void

    var body: some View {
        Card {
            EmptyState(
                symbol: "person.2",
                title: "No students yet",
                line: "Add a student by hand, or photograph a page of your paper register and we read the names into a "
                    + "list you check.",
                actions: (
                    .init("Add a student", emphasis: .primary, run: addStudent),
                    .init("Scan paper register", run: scanRegister)
                )
            )
        }
    }
}

/// The Classes section while no class exists (P3-Students-Empty and -Few): the empty row and Create a class.
struct NoClassesSection: View {
    let createClass: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Batches")
            Card {
                EmptyState(
                    symbol: "book.closed",
                    title: "No batches yet",
                    line: "A batch is the students you teach together, with its days and times. Each student can be in "
                        + "one.",
                    action: .init("Create a batch", run: createClass)
                )
            }
        }
    }
}

/// The "+" menu's three rows (P3-Students-AddMenu), shown in the system popover: label body left, symbol 20 right,
/// 46 high, 260 wide, divided by lineGlass.
struct AddMenu: View {
    let addStudent: () -> Void
    let scanRegister: () -> Void
    let createClass: () -> Void
    static var width: CGFloat {
        260
    }

    var body: some View {
        VStack(spacing: 0) {
            row("Add a student", symbol: "person.badge.plus", action: addStudent).rowDivider(glass: true)
            row("Scan paper register", symbol: "doc.viewfinder", action: scanRegister).rowDivider(glass: true)
            row("New batch", symbol: "book.closed", action: createClass)
        }
        .frame(width: Self.width)
    }

    private func row(_ label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                Spacer(minLength: 0)
                Image(systemName: symbol).accessibilityHidden(true).font(.system(size: Tokens.iconButton))
                    .foregroundStyle(Tokens.text.color)
            }
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(height: Well<EmptyView>.height)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// A refresh that failed: the line and Retry (Today's pattern).
struct ErrorLine: View {
    let text: String
    let retry: () -> Void

    init(_ text: String, retry: @escaping () -> Void) {
        self.text = text
        self.retry = retry
    }

    var body: some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry", action: retry).buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}

extension TrackStatus {
    /// The Kit's tone and symbol for the status (DesignSystem imports nothing).
    var kind: TrackKind {
        switch self {
        case .notOnTrack: .notOnTrack
        case .watch: .watch
        case .onTrack: .onTrack
        case .notKnown: .notKnown
        }
    }
}
