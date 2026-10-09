import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Schedule

@MainActor struct EventFormStoreTests {
    @Test func aNewEventNeedsATitleAndKeepsItsTimesInOrder() throws {
        let store = try EventFormStore(mode: .new(#require(Day(year: 2026, month: 10, day: 10))))
        #expect(store.heading == "New event" && !store.canSave && store.isChanged == false)
        store.title = "Parents' meeting"
        #expect(store.canSave && store.isChanged)
        store.setEnd(TimeOfDay(hour: 12, minute: 0))
        #expect(store.startTime == TimeOfDay(hour: 11, minute: 0), "an end alone takes a start an hour before")
        store.setStart(TimeOfDay(hour: 12, minute: 30))
        #expect(!store.canSave && store.timeError == "The event has to end after it starts.")
        store.setEnd(nil)
        #expect(store.canSave && store.timeError == nil)
    }

    @Test func editingIsSaveableOnlyOnceChanged() {
        let store = EventFormStore(mode: .edit(FakeEventsRepository.parentsMeeting))
        #expect(store.heading == "Edit event" && store.title == "Parents' meeting" && !store.canSave && !store
            .isChanged)
        store.note = "Bring the papers."
        #expect(store.canSave && store.draft.trimmedNote == "Bring the papers.")
    }

    @Test func theContentIsNeverShorterThanTheSheetSoDeleteSitsAtTheBottomUntilTheKeyboardComes() {
        // The sheet's room minus its header: the content fills it, so Delete event is at the bottom with the keyboard
        // away; with the keyboard up the same height keeps the fields where they were and Delete scrolls under it (U7).
        #expect(EventFormSheet.contentMinHeight(sheetHeight: 796, headerHeight: 44) == 796 - 44 - Tokens.sectionGap)
        #expect(EventFormSheet.contentMinHeight(sheetHeight: 0, headerHeight: 44) == 0)
    }

    @Test func theGapAboveDeleteTakesTheRoomTheFieldsLeaveSoTheNoteKeepsItsSize() {
        // 796 of room under a 44 header: 796 - 44 - sectionGap for the column; the fields (500) and Delete (52) take
        // theirs and the gap takes the rest, never less than a section's gap (a long note pushes Delete down).
        let column = 796 - 44 - Tokens.sectionGap
        #expect(EventFormSheet.deleteGap(sheetHeight: 796, headerHeight: 44, fieldsHeight: 500, deleteHeight: 52)
            == column - 500 - 52)
        #expect(EventFormSheet.deleteGap(sheetHeight: 796, headerHeight: 44, fieldsHeight: 900, deleteHeight: 52)
            == Tokens.sectionGap)
    }
}
