import Testing
@testable import Today

/// U11, U19: the two launch states drawn scrolled down Today get room below the page to scroll to; a tutor's Today has
/// none.
struct TodayBoardScrollTests {
    @Test func onlyTheScrolledBoardsGetRoomBelow() {
        #expect(TodayView.roomBelow(.aiRow) && TodayView.roomBelow(.addingTask))
        #expect(!TodayView.roomBelow(nil) && !TodayView.roomBelow(.noteDayWheel))
    }
}
