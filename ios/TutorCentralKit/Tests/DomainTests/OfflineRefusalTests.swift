import Domain
import Testing

struct OfflineRefusalTests {
    @Test func everyRefusedWriteIsNamed() {
        #expect(OfflineRefusal.words(for: .addStudent)
            == "You're offline. Adding a student needs a connection; nothing was saved.")
        #expect(OfflineRefusal.words(for: .generateFees)
            == "You're offline. Creating the month's fees needs a connection; nothing was created.")
        #expect(OfflineRefusal
            .words(for: .remind) == "You're offline. Reminders need a connection to be noted on the fee.")
        #expect(OfflineRefusal.Write.allCases
            .allSatisfy { OfflineRefusal.words(for: $0).hasPrefix("You're offline. ") })
    }

    @Test func theNewRefusalsArePlain() {
        for write in [OfflineRefusal.Write.consent, .textbook, .placement, .homeworkStatus, .addChapter] {
            let words = OfflineRefusal.words(for: write)
            #expect(words.hasPrefix("You're offline.") && !words.lowercased().contains("server"))
        }
        #expect(OfflineRefusal.words(for: .textbook) ==
            "You're offline. Reading a contents page needs a connection; nothing was saved.")
        #expect(OfflineRefusal.words(for: .consent) ==
            "You're offline. Recording consent needs a connection; nothing was saved.")
        #expect(OfflineRefusal.words(for: .placement) == "You're offline. The placement's questions need a connection.")
        #expect(OfflineRefusal.words(for: .homeworkStatus) ==
            "You're offline. Marking homework needs a connection; nothing was changed.")
        #expect(OfflineRefusal.words(for: .addChapter) ==
            "You're offline. Adding a chapter needs a connection; nothing was saved.")
    }
}
