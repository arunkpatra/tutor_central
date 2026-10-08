import Students
import SwiftUI

/// Where the Students screens' buttons lead: other tabs and screens AppShell owns.
extension RootView {
    var studentsActions: StudentsActions {
        StudentsActions(
            openScanRegister: { shell.tabs.push(.later(.scanRegister)) },
            openStudentFees: { _ in shell.tabs.push(.later(.studentFees)) },
            openMarkAttendance: { id in
                guard case let .ready(workspace) = session.state else { return }
                openAttendance(classID: id, date: nil, in: workspace)
            },
            openStudentAttendance: { shell.tabs.push(.historyStudent($0)) }
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
            }
        )
    }
}
