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

    @Test func thePlansRefusalsNameWhatWasNotChanged() {
        #expect(OfflineRefusal.words(for: .regenerate)
            == "You're offline. Making it again needs a connection; the sheet you have is still here.")
        #expect(OfflineRefusal.words(for: .changePlan)
            == "You're offline. Changing the plan needs a connection; nothing was changed.")
        #expect(OfflineRefusal.words(for: .ownSheet)
            == "You're offline. Using your own sheet needs a connection; nothing was changed.")
    }
}

struct OfflineRefusalSchoolTests {
    @Test func theSchoolRefusalsNameWhatWaits() {
        #expect(OfflineRefusal.words(for: .schoolItem)
            == "You're offline. Keeping what the school sent needs a connection; nothing was kept.")
        #expect(OfflineRefusal.words(for: .readSchool)
            ==
            "You're offline. Reading what the school sent needs a connection; it waits here until you're back online.")
        #expect(OfflineRefusal.words(for: .forwardAsk)
            == "You're offline. Sending needs a connection to note who was asked.")
        #expect(OfflineRefusal
            .words(for: .mark) == "You're offline. Marking needs a connection; the photos are still here.")
        #expect(OfflineRefusal.words(for: .gapReport) == "You're offline. The gap report needs a connection.")
        #expect(OfflineRefusal.words(for: .testTomorrow)
            == "You're offline. Sending needs a connection to note it on the student's page.")
        for write in [OfflineRefusal.Write.schoolItem, .readSchool, .forwardAsk, .mark, .gapReport] {
            #expect(!ErrorWordsTests.banned.contains { OfflineRefusal.words(for: write).lowercased().contains($0) })
        }
    }

    @Test func theThreeReadingRefusalsSayWhatWaits() {
        #expect(OfflineRefusal.words(for: .readShared).contains("waits here"))
        #expect(!OfflineRefusal.words(for: .readPasted).contains("waits here"))
        #expect(OfflineRefusal.words(for: .readPasted).contains("Try again"))
        #expect(!OfflineRefusal.words(for: .readPhoto).contains("waits here"))
        #expect(OfflineRefusal.words(for: .readPhoto).contains("Try again"))
    }

    @Test func theParentsWritesSayTheyNeedAConnection() {
        for write in [OfflineRefusal.Write.weeklyNote, .readMarks, .notOnTrack, .noteDay, .nextStep, .saveMarks] {
            #expect(OfflineRefusal.words(for: write).hasPrefix("You're offline."), "\(write)")
        }
        #expect(OfflineRefusal.words(for: .weeklyNote)
            == "You're offline. The note is written from this week's record and needs a connection.")
        #expect(OfflineRefusal.words(for: .saveMarks).hasSuffix("They're still here."))
    }
}
