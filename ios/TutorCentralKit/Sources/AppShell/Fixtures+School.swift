import Data
import Domain
import Foundation
import School

/// The School tab's boards (Phase 13): the Evening batch's items, the message read, an item's page.
extension Fixtures {
    static let schoolStates: Set<LaunchState> = [
        .schoolEmpty, .school, .schoolCalendar, .schoolAddMenu, .schoolReading, .schoolConfirm, .schoolConfirmEdit,
        .schoolItem, .schoolItemEdit, .schoolItemDelete, .schoolLastDays, .gapReport,
        .schoolItemHomework, .schoolItemHoliday, .schoolAsk, .schoolAskFailed,
        .schoolTestTomorrow,
    ]

    /// The exam's page (P10-School-Item, -Edit, -Delete): the Evening batch's five with the plan's statuses, so
    /// Preparation reads the Evening batch's days.
    static let examPageStates: Set<LaunchState> = [
        .schoolItem, .schoolItemEdit, .schoolItemDelete, .schoolLastDays, .gapReport,
    ]

    /// The last days' states: Wednesday 14 October after the class, the mock marked for Dev and Meher.
    static let lastDaysStates: Set<LaunchState> = [.schoolLastDays, .gapReport]

    /// Dev's parent writes in Hindi and agreed (P10-TestTomorrow, P10-Today-AfterClose's "Dev's father · Hindi").
    static func withSchoolLanguages(_ students: [Student], for state: LaunchState) -> [Student] {
        if lastDaysStates.contains(state) {
            // P10-School-Exam-LastDays: Dev's and Meher's parents agreed; Nikhil's not yet.
            return students.map { student in
                guard [FakeStudentsRepository.dev, FakeStudentsRepository.meher].contains(student.id),
                      let phone = student.parentPhone else { return student }
                var changed = student
                changed.consent = ConsentRecord(at: india(day: 1, hour: 17, minute: 0), phone: phone, how: .inPerson)
                return changed
            }
        }
        guard [.schoolTestTomorrow, .todayAfterClose].contains(state) else { return students }
        return students.map { student in
            guard student.id == FakeStudentsRepository.dev, let phone = student.parentPhone else { return student }
            var changed = student
            changed.messageLanguage = .hindi
            changed.gender = .male
            changed.consent = ConsentRecord(at: india(day: 1, hour: 17, minute: 0), phone: phone, how: .inPerson)
            return changed
        }
    }

    /// The Test tomorrow sheet the state opens over Dev's exam.
    static func testTomorrowAsk(for state: LaunchState) -> TestTomorrowAsk? {
        guard state == .schoolTestTomorrow,
              let item = FakeSchoolItemsRepository.boardItems
              .first(where: { $0.id == FakeSchoolItemsRepository.devsTest }),
              let dev = withSchoolLanguages(FakeStudentsRepository.seed, for: state)
              .first(where: { $0.id == FakeStudentsRepository.dev }) else { return nil }
        return TestTomorrowAsk(item: item, student: dev)
    }

    /// P10-School-Ask: Dev's and Meher's parents asked already.
    static func forwardAsked(for state: LaunchState) -> [UUID: [MessageEntry]] {
        guard state == .schoolAsk else { return [:] }
        let asked = { MessageEntry(id: UUID(), kind: .forwardAsk, openedAt: clock(for: state), language: nil) }
        return [FakeStudentsRepository.dev: [asked()], FakeStudentsRepository.meher: [asked()]]
    }

    @MainActor static func schoolItems(for state: LaunchState) -> FakeSchoolItemsRepository {
        let items: [SchoolItem] = switch state {
        case .schoolEmpty: []
        // P10-Today-NotOnTrack: no exam near, so Dev's line teaches again as the board draws it.
        case _ where notOnTrackStates.contains(state): []
        // P13-Today-Revision: Science unit test 3 alone, so Dev revises with Meher and Nikhil.
        case .todayRevision: FakeSchoolItemsRepository.boardItems.filter {
                $0.id == FakeSchoolItemsRepository.scienceTest3
            }
        default: FakeSchoolItemsRepository.boardItems
        }
        return FakeSchoolItemsRepository(items: items, now: clock(for: state))
    }
}

extension RootView {
    /// What each School state opens on the School tab's stack.
    static func schoolRoutes(for state: LaunchState) -> [Route]? {
        switch state {
        case .schoolReading, .schoolConfirm, .schoolConfirmEdit:
            [.schoolRead(.pasted(FakeSchoolItemsRepository.boardMessage))]
        case .schoolItem, .schoolItemEdit, .schoolItemDelete, .schoolLastDays:
            [.schoolItem(FakeSchoolItemsRepository.scienceTest3)]
        case .gapReport:
            [
                .schoolItem(FakeSchoolItemsRepository.scienceTest3),
                .schoolGapReport(FakeSchoolItemsRepository.scienceTest3, FakeStudentsRepository.dev),
            ]
        case .schoolItemHomework: [.schoolItem(FakeSchoolItemsRepository.mathsHomework)]
        case .schoolItemHoliday: [.schoolItem(FakeSchoolItemsRepository.dasara)]
        case .schoolAsk, .schoolAskFailed: [.schoolAsk]
        case .schoolTestTomorrow: [.schoolItem(FakeSchoolItemsRepository.devsTest)]
        default: nil
        }
    }

    /// The exam page's edit sheet and delete dialog (P10-School-Item-Edit, -Delete).
    static func itemBoardState(_ state: LaunchState?) -> ItemBoardState? {
        switch state {
        case .schoolItemEdit: .edit
        case .schoolItemDelete: .delete
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
