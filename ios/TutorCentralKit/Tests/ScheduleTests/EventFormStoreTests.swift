import Data
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
}
