import Testing
@testable import Domain

struct RecordTests {
    @Test func trackingStatusMatchesTheDatabaseAndSortsTheListAsTheBoards() {
        #expect(TrackStatus.allCases.map(\.rawValue) == ["not_on_track", "watch", "on_track", "not_known"])
        #expect(TrackStatus.allCases.map(\.title) == ["Not on track", "Watch", "On track", "Not known yet"])
        #expect([TrackStatus.notKnown, .onTrack, .notOnTrack, .watch].sorted() == [
            .notOnTrack,
            .watch,
            .onTrack,
            .notKnown,
        ])
    }

    @Test func skillStatesAndHowConsentWasGivenMatchTheDatabase() {
        #expect(SkillState.allCases.map(\.rawValue) == ["not_started", "taught", "practising", "secure", "revisit"])
        #expect(ConsentMethod.allCases.map(\.rawValue) == ["in_person", "call", "whatsapp"])
        #expect(ConsentMethod.allCases.map(\.title) == ["In person", "On a call", "On WhatsApp"])
    }
}
