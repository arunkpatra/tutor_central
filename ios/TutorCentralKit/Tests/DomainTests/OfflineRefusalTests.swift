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
}
