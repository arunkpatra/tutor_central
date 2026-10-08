import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the Students root so it can be photographed beside its board: the search typed and
/// focused, a class filter with the fee sort, the "+" menu open.
public enum StudentsBoardState: Sendable {
    case searching
    case filteredToScience
    case addMenu
    case newStudentEmpty
    case newStudentFilled
    case newStudentInvalid
}

/// Pushes on the Students tab. AppShell owns the stack; the feature asks for a screen.
public struct StudentsNavigation {
    let openStudent: (UUID) -> Void
    let openClasses: () -> Void
    let openClass: (UUID) -> Void
    let showUnassigned: () -> Void

    /// `showUnassigned` goes back to the list with the "No class" filter on.
    public init(
        openStudent: @escaping (UUID) -> Void,
        openClasses: @escaping () -> Void,
        openClass: @escaping (UUID) -> Void,
        showUnassigned: @escaping () -> Void
    ) {
        self.openStudent = openStudent
        self.openClasses = openClasses
        self.openClass = openClass
        self.showUnassigned = showUnassigned
    }
}

/// The Students root, to P3-Students-Empty, -Few, -Many (dark and light), -Searching, -Filtered and -AddMenu: the
/// title with the "+" menu, the search, the filter chips, the Classes row, the count line with the sort, the list.
public struct StudentsView: View {
    @Bindable var store: RegisterStore
    let actions: StudentsActions
    let navigation: StudentsNavigation
    let boardState: StudentsBoardState?
    @State private var searching = false
    @State private var showsMenu = false
    @State private var newStudent: StudentFormStore?
    @State private var newClass: ClassFormStore?
    @State private var topInset: CGFloat = 0
    /// The inline title row while searching (P3-Students-Searching): a navigation bar's height.
    static var inlineTitleHeight: CGFloat {
        44
    }

    public init(
        store: RegisterStore,
        actions: StudentsActions,
        navigation: StudentsNavigation,
        boardState: StudentsBoardState? = nil
    ) {
        self.store = store
        self.actions = actions
        self.navigation = navigation
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                titleRow
                if isEmpty {
                    NoStudentsCard(addStudent: addStudent, scanRegister: actions.openScanRegister)
                } else {
                    SearchAndFilters(store: store, searching: $searching, showsFocus: boardState == .searching)
                    if !searching, !store.activeClasses.isEmpty {
                        ClassesRow(classes: store.activeClasses, open: navigation.openClasses)
                    }
                    RegisterList(store: store, searching: searching, openStudent: navigation.openStudent)
                    if !searching, case let .classroom(id) = store.filter, let classroom = store.classroom(id) {
                        ClassFooter(classroom: classroom) { navigation.openClass(id) }
                    }
                }
                // Only once something has been read: a failed first read says so above, it is not "no classes".
                if !store.loading, !searching, store.activeClasses.isEmpty,
                   store.showsEmptyRegister || !store.students.isEmpty {
                    NoClassesSection(createClass: createClass)
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            await store.refresh()
            Haptic.play(.impactLight)
        }
        .sheet(item: $newStudent) { form in
            StudentFormSheet(
                store: form,
                showsFocus: boardState == .newStudentEmpty,
                autofocus: boardState == nil,
                onSave: { await store.addStudent($0) != nil },
                onClose: { newStudent = nil }
            )
        }
        .sheet(item: $newClass) { form in
            ClassFormSheet(
                store: form,
                autofocus: true,
                onSave: { await store.addClass($0) != nil },
                onClose: { newClass = nil }
            )
        }
        .task {
            await store.load()
            setUpBoardState()
        }
        // Saved: the success haptic, for every write the register makes from any Students screen.
        .onChange(of: store.lastSavedAt) { Haptic.play(.success) }
    }

    private var isEmpty: Bool {
        store.showsEmptyRegister
    }

    @ViewBuilder private var titleRow: some View {
        if searching {
            Text("Students")
                .typeStyle(Tokens.headline)
                .foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, minHeight: Self.inlineTitleHeight)
                .accessibilityAddTraits(.isHeader)
        } else {
            HStack(alignment: .bottom) {
                Text("Students")
                    .typeStyle(Tokens.display)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Tokens.inline)
                Button { showsMenu = true } label: { IconButtonLook(symbol: "plus") }
                    .pressable()
                    .accessibilityLabel("Add")
                    .popover(isPresented: $showsMenu, arrowEdge: .top) {
                        AddMenu(
                            addStudent: { menuChose(addStudent) },
                            scanRegister: { menuChose(actions.openScanRegister) },
                            createClass: { menuChose(createClass) }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
            }
        }
    }

    private func menuChose(_ action: @escaping () -> Void) {
        showsMenu = false
        action()
    }

    private func addStudent() {
        newStudent = StudentFormStore(mode: .new, classes: store.activeClasses, today: store.today)
    }

    private func createClass() {
        newClass = ClassFormStore(mode: .new)
    }

    private func setUpBoardState() {
        switch boardState {
        case .searching:
            store.search = "sh"
            searching = true
        case .filteredToScience:
            store.filter = .classroom(FakeClassesRepository.science.id)
            store.sort = .fee
        case .addMenu:
            showsMenu = true
        case .newStudentEmpty:
            addStudent()
        case .newStudentFilled, .newStudentInvalid:
            newStudent = StudentFormSheet.fixture(
                invalid: boardState == .newStudentInvalid,
                classes: store.activeClasses,
                today: store.today
            )
        case nil:
            break
        }
    }
}
