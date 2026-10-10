import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state opens over the Classes list: the new class sheet, or Class 10 Maths' edit sheet (with its
/// archive confirmation), as P3-NewClass and P3-EditClass draw them over this list.
public enum ClassesBoardState: Sendable {
    case newClass
    case editMaths
    case archiveMaths
}

/// The classes, to P3-Classes-Empty and P3-Classes-List: each active class with its meeting summary and member count,
/// then the students in no class.
public struct ClassesView: View {
    let register: RegisterStore
    let navigation: StudentsNavigation
    let boardState: ClassesBoardState?
    @State private var form: ClassFormStore?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(register: RegisterStore, navigation: StudentsNavigation, boardState: ClassesBoardState? = nil) {
        self.register = register
        self.navigation = navigation
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                navigationRow
                if register.activeClasses.isEmpty {
                    Card {
                        EmptyState(
                            symbol: "book.closed",
                            title: "No batches yet",
                            line: "Batches you add appear here with their meeting days and fee. "
                                + "A batch takes attendance in one go and gives new students their fee.",
                            action: .init("Create a batch", emphasis: .primary, run: createClass)
                        )
                    }
                } else {
                    classes
                }
                if !register.unassigned.isEmpty {
                    unassigned
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $form) { form in
            ClassFormSheet(
                store: form,
                membersCount: membersCount(form),
                confirmsArchive: boardState == .archiveMaths,
                onSave: { draft in await save(draft, form: form) },
                onArchive: archiveAction(form),
                onClose: { self.form = nil }
            )
        }
        .task {
            await register.loadIfNeeded()
            setUpBoardState()
        }
    }

    private var navigationRow: some View {
        ZStack {
            Text("Batches").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
                IconButton(symbol: "plus", label: "Create a batch", action: createClass)
            }
        }
    }

    private var classes: some View {
        let shown = register.activeClasses
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(shown.count == 1 ? "1 batch" : "\(shown.count) batches")
            Card {
                VStack(spacing: 0) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, classroom in
                        ClassRow(
                            name: classroom.name,
                            summary: classroom.meetingSummary,
                            members: register.members(of: classroom.id).count
                        ) { navigation.openClass(classroom.id) }
                            .rowDivider(index < shown.count - 1)
                    }
                }
            }
        }
    }

    private var unassigned: some View {
        let students = register.unassigned
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Not in a batch")
            ClassRow(
                symbol: "person.crop.circle.badge.questionmark",
                name: students.count == 1 ? "1 student" : "\(students.count) students",
                summary: students.map(\.name).joined(separator: ", "),
                members: nil
            ) { navigation.showUnassigned() }
                .lineLimit(1)
                .surface(radius: Tokens.radiusCard)
            Text("A student without a batch is counted and billed on their own fee; attendance is taken by batch.")
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }

    private func createClass() {
        form = ClassFormStore(mode: .new)
    }

    private func membersCount(_ form: ClassFormStore) -> Int {
        if case let .edit(classroom) = form.mode {
            return register.members(of: classroom.id).count
        }
        return 0
    }

    private func save(_ draft: ClassroomDraft, form: ClassFormStore) async -> Bool {
        if case let .edit(classroom) = form.mode {
            return await register.updateClass(classroom.id, with: draft)
        }
        return await register.addClass(draft) != nil
    }

    private func archiveAction(_ form: ClassFormStore) -> (() async -> Void)? {
        guard case let .edit(classroom) = form.mode else { return nil }
        return { await register.archiveClass(classroom.id) }
    }

    private func setUpBoardState() {
        switch boardState {
        case .newClass: form = ClassFormSheet.fixture()
        case .editMaths, .archiveMaths:
            if let maths = register.classroom(FakeClassesRepository.maths.id) {
                form = ClassFormStore(mode: .edit(maths))
            }
        case nil: break
        }
    }
}
