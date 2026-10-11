import Testing
@testable import DesignSystem

/// U20 (P15-Consent-Note): the centre's consent sheet speaks of what asked for it, a photo or a note.
struct ConsentSheetWordsTests {
    @Test func theConsentSheetForANoteSpeaksOfNotes() {
        #expect(ConsentSheet.title(.note) == "Before the first note")
        #expect(ConsentSheet.text(.note).hasPrefix("A note about a student carries their name and what you have seen"))
        #expect(!ConsentSheet.text(.note).contains("photo"))
    }

    @Test func thePhotosSheetIsUnchanged() {
        #expect(ConsentSheet.title(.photo) == "Before the first photo")
        #expect(ConsentSheet.text(.photo) == ConsentSheet.text)
    }
}
