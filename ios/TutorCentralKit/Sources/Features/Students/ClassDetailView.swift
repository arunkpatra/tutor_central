import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state opens over the class detail: the add-students sheet with Sahil chosen.
public enum ClassDetailBoardState: Sendable {
    case addMembers
}

/// One class, to P3-ClassDetail: the header, this week's meetings with today marked and Mark attendance (later), the
/// members with Add; a member leaves the class through the row's menu. Edit opens the class form with Archive class.
public struct ClassDetailView: View {
    let id: UUID
    let register: RegisterStore
    let actions: StudentsActions
    let navigation: StudentsNavigation
    let boardState: ClassDetailBoardState?
    @State private var editing: ClassFormStore?
    @State private var adding = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        id: UUID,
        register: RegisterStore,
        actions: StudentsActions,
        navigation: StudentsNavigation,
        boardState: ClassDetailBoardState? = nil
    ) {
        self.id = id
        self.register = register
        self.actions = actions
        self.navigation = navigation
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            if let classroom = register.classroom(id), !classroom.isArchived {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    navigationRow(classroom)
                    header(classroom)
                    week(classroom)
                    members
                }
                .padding(.horizontal, Tokens.pageSide)
                .padding(.top, max(0, Tokens.pageTop - topInset))
                .padding(.bottom, Tokens.contentBottom)
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $editing) { form in
            ClassFormSheet(
                store: form,
                membersCount: register.members(of: id).count,
                onSave: { await register.updateClass(id, with: $0) },
                onArchive: {
                    await register.archiveClass(id)
                    // Only when it took: a failed archive is rolled back and says so, and the class is still here.
                    if register.classroom(id)?.isArchived == true {
                        dismiss()
                    }
                },
                onClose: { editing = nil }
            )
        }
        .sheet(isPresented: $adding) {
            if let classroom = register.classroom(id) {
                AddMembersSheet(
                    classroom: classroom,
                    candidates: register.activeStudents
                        .filter { $0.classID != id }
                        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
                    classNames: { register.classroom($0)?.name ?? "No class yet" },
                    preselected: boardState == .addMembers ? Self.boardPick(register) : [],
                    onAdd: { await register.assign($0, to: id) },
                    onClose: { adding = false }
                )
            }
        }
        .task {
            await register.loadIfNeeded()
            if boardState == .addMembers {
                adding = true
            }
        }
    }

    private func navigationRow(_ classroom: Classroom) -> some View {
        ZStack {
            Text(classroom.name)
                .typeStyle(Tokens.headline)
                .foregroundStyle(Tokens.text.color)
                .lineLimit(1)
                .padding(.horizontal, IconButton.size + Tokens.inline)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
                Button("Edit") { editing = ClassFormStore(mode: .edit(classroom)) }.buttonStyle(.quiet)
            }
        }
    }

    private func header(_ classroom: Classroom) -> some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            IconTile(symbol: "book.closed", size: .header)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                Text(classroom.name)
                    .typeStyle(Tokens.title1)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    [
                        classroom.subject,
                        classroom.meetingSummary,
                        classroom.monthlyFee.map { "\($0.formatted) a month" },
                    ]
                    .compactMap(\.self)
                    .joined(separator: " · ")
                )
                .typeStyle(Tokens.footnote)
                .monospacedDigit()
                .foregroundStyle(Tokens.text2.color)
            }
        }
    }

    private func week(_ classroom: Classroom) -> some View {
        let today = register.today
        let meetings = classroom.meetings(inWeekOf: today, calendar: DayHeading.india)
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("This week", action: ("Mark attendance", { actions.openMarkAttendance(id) }))
            Card {
                if meetings.isEmpty {
                    EmptyRow(
                        symbol: "calendar",
                        title: "No fixed days yet",
                        line: "Set the days it meets in Edit to see the week here."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(meetings.enumerated()), id: \.element) { index, day in
                            MeetingRow(
                                day: day.weekday(in: DayHeading.india).short,
                                title: day == today ? "Today, \(day.longText)" : day.longText,
                                time: classroom.timeRange,
                                isToday: day == today
                            )
                            .rowDivider(index < meetings.count - 1)
                        }
                    }
                }
            }
        }
    }

    private var members: some View {
        let members = register.members(of: id)
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(members.count == 1 ? "1 student" : "\(members.count) students", action: ("Add", {
                adding = true
            }))
            Card {
                if members.isEmpty {
                    EmptyRow(
                        symbol: "person.2",
                        title: "No students yet",
                        line: "Add students from the register, or pick this class when you add one."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(members.enumerated()), id: \.element.id) { index, student in
                            MemberRow(
                                initials: student.initials,
                                name: student.name,
                                phone: student.parentPhone?.display ?? "No number yet",
                                fee: student.monthlyFee?.formatted
                            ) { navigation.openStudent(student.id) }
                                .contextMenu {
                                    Button("Remove from class", systemImage: "person.badge.minus", role: .destructive) {
                                        Task { await register.assign([student.id], to: nil) }
                                    }
                                }
                                .rowDivider(index < members.count - 1)
                        }
                    }
                }
            }
        }
    }

    /// P3-ClassDetail-AddMembers: Sahil Verma chosen.
    private static func boardPick(_ register: RegisterStore) -> Set<UUID> {
        Set(register.activeStudents.filter { $0.name == "Sahil Verma" }.map(\.id))
    }
}
