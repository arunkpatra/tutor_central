import Data
import DesignSystem
import Domain
import Students
import SwiftUI

/// Where the Students screens' buttons lead: other tabs and screens AppShell owns.
extension RootView {
    var studentsActions: StudentsActions {
        StudentsActions(
            openScanRegister: { shell.tabs.push(.scanRegister) },
            openStudentFees: { shell.tabs.push(.studentFees($0)) },
            openMarkAttendance: { id in
                guard case let .ready(workspace) = session.state else { return }
                openAttendance(classID: id, date: nil, in: workspace)
            },
            openStudentAttendance: { shell.tabs.push(.historyStudent($0)) },
            openFeeAction: { openFeeAction($0) },
            openToday: { shell.openToday(batch: $0) },
            openArtefact: { shell.tabs.push(.artefact($0)) }
        )
    }

    var studentsNavigation: StudentsNavigation {
        StudentsNavigation(
            openStudent: { shell.tabs.push(.student($0)) },
            openClasses: { shell.tabs.push(.classes) },
            openClass: { shell.tabs.push(.classroom($0)) },
            showUnassigned: {
                shell.tabs.paths[.students] = []
                shell.register?.filter = .unassigned
            },
            openTextbook: { shell.tabs.push(.textbook(student: $0, subject: $1)) },
            openPlacement: { shell.tabs.push(.placement($0)) }
        )
    }
}

/// Add a textbook (P10-Textbook-*): its store made once the register has the student and the school (a launch state or
/// a link can open it before the register is read), then kept for the screen's life (ios/CLAUDE.md). A student without
/// a school never reaches it (plan decision 11).
struct TextbookScreen: View {
    @State private var store: TextbookStore?
    let register: RegisterStore
    let make: @MainActor () -> TextbookStore?
    let boardState: TextbookBoardState?
    let sample: ImageUpload?

    var body: some View {
        Group {
            if let store {
                TextbookView(store: store, boardState: boardState, sample: sample)
            } else {
                Tokens.ground.color.ignoresSafeArea()
            }
        }
        .task {
            await register.loadIfNeeded()
            if store == nil {
                store = make()
            }
        }
    }
}

extension RootView {
    @ViewBuilder func textbookView(student id: UUID, subject: String?) -> some View {
        if case let .ready(workspace) = session.state {
            let register = register(for: workspace)
            TextbookScreen(
                register: register,
                make: { register.student(id).flatMap { student in
                    student.schoolID.flatMap { school in register.schools.first { $0.id == school } }.map { school in
                        TextbookStore(
                            student: student, school: school, register: register, ai: deps.ai,
                            textbooks: deps.textbooks, subject: subject,
                            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                        )
                    }
                } },
                boardState: launch.flatMap(Self.textbookBoardState),
                sample: launch.map(Fixtures.scanSample)
            )
        }
    }
}

extension RootView {
    @ViewBuilder func studentDetailView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            let register = register(for: workspace)
            StudentDetailView(
                store: StudentDetailStore(
                    id: id, register: register, attendance: deps.attendance, messages: deps.messages,
                    textbooks: deps.textbooks, record: deps.record, now: deps.now,
                    online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                ),
                register: register,
                actions: studentsActions,
                navigation: studentsNavigation,
                boardState: launch.flatMap(Self.studentDetailBoardState),
                onMissing: {
                    shell.tabs.remove(.student(id))
                    notices.show(StudentDetailStore.missingMessage)
                },
                onMessage: { notices.show($0) }
            )
        }
    }
}

extension RootView {
    /// The placement, its store made for the visit (the page's store is AppShell's to keep).
    @ViewBuilder func placementView(_ id: UUID) -> some View {
        if case let .ready(workspace) = session.state {
            PlacementView(
                store: PlacementStore(
                    studentID: id, register: register(for: workspace), ai: deps.ai, textbooks: deps.textbooks,
                    record: deps.record, attendance: deps.attendance, now: deps.now,
                    online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                ),
                boardTaps: launch == .placement ? [true, true, false] : []
            )
        }
    }
}
