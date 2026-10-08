import Data
import DesignSystem
import Domain
import Onboarding
import Students
import SwiftUI

/// How each launch state sets the root up: its tab, what its stack opens, and the board state a screen is told.
extension RootView {
    static func tab(for state: LaunchState) -> AppTab? {
        switch state {
        case .laterStudents, .studentsEmpty, .studentsFew, .students, .studentsSearching, .studentsFiltered,
             .studentsAddMenu, .studentNew, .studentNewFilled, .studentNewInvalid, .student, .studentArchived,
             .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit: .students
        case .laterFees: .fees
        case .laterAttendance: .attendance
        case .laterMore: .more
        default: nil
        }
    }

    /// What a launch state opens on its tab's stack: Settings, or Akshita's detail.
    static func initialRoutes(for state: LaunchState) -> [Route] {
        switch state {
        case .settings: [.settings]
        case .student, .studentArchived, .studentArchiveConfirm, .studentDeleteConfirm, .studentEdit:
            [.student(FakeStudentsRepository.akshita)]
        default: []
        }
    }

    static func signInFixture(_ state: LaunchState) -> SignInFixture? {
        switch state {
        case .signinEmail: .email
        case .signinCode: .code
        case .signinCodeWrong: .codeWrong
        case .signinPassword: .password
        default: nil
        }
    }

    static func studentDetailBoardState(_ state: LaunchState) -> StudentDetailBoardState? {
        switch state {
        case .studentArchiveConfirm: .archiveConfirm
        case .studentDeleteConfirm: .deleteConfirm
        case .studentEdit: .edit
        default: nil
        }
    }

    static func studentsBoardState(_ state: LaunchState) -> StudentsBoardState? {
        switch state {
        case .studentsSearching: .searching
        case .studentsFiltered: .filteredToScience
        case .studentsAddMenu: .addMenu
        case .studentNew: .newStudentEmpty
        case .studentNewFilled: .newStudentFilled
        case .studentNewInvalid: .newStudentInvalid
        default: nil
        }
    }
}
