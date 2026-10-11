import Data
import Domain
import Foundation
import School

/// The School tab's boards (Phase 13): the Evening batch's items, the message read, an item's page.
extension Fixtures {
    static let schoolStates: Set<LaunchState> = [
        .schoolEmpty, .school, .schoolCalendar, .schoolAddMenu, .schoolReading, .schoolConfirm, .schoolConfirmEdit,
        .schoolItemHomework, .schoolItemHoliday,
    ]

    @MainActor static func schoolItems(for state: LaunchState) -> FakeSchoolItemsRepository {
        FakeSchoolItemsRepository(
            items: state == .schoolEmpty ? [] : FakeSchoolItemsRepository.boardItems, now: clock(for: state)
        )
    }
}

extension RootView {
    /// What each School state opens on the School tab's stack.
    static func schoolRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .schoolReading, .schoolConfirm, .schoolConfirmEdit:
            [.schoolRead(.pasted(FakeSchoolItemsRepository.boardMessage))]
        case .schoolItemHomework: [.schoolItem(FakeSchoolItemsRepository.mathsHomework)]
        case .schoolItemHoliday: [.schoolItem(FakeSchoolItemsRepository.dasara)]
        default: nil
        }
    }

    static func schoolBoardState(_ state: LaunchState) -> SchoolBoardState? {
        switch state {
        case .schoolAddMenu: .addMenu
        case .schoolCalendar: .calendar(FakeSchoolItemsRepository.day(16))
        default: nil
        }
    }
}
