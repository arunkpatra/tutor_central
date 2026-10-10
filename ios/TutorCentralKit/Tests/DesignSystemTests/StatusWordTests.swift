import Testing
@testable import DesignSystem

struct StatusWordTests {
    @Test func theStatusWordsTonesAndSymbols() {
        #expect(TrackKind.onTrack.tone == .ok && TrackKind.watch.tone == .due && TrackKind.notOnTrack.tone == .overdue)
        #expect(TrackKind.notKnown.tone == nil)
        #expect(TrackKind.watch.symbol == "clock" && TrackKind.notKnown.symbol == "circle")
        #expect(TrackKind.onTrack.symbol == "checkmark.circle" && TrackKind.notOnTrack
            .symbol == "exclamationmark.circle")
    }

    @Test func aPickerValueNotChosenShowsItsPlaceholderQuietly() {
        #expect(PickerValue.shown(value: nil, placeholder: "Choose") == ("Choose", true))
        #expect(PickerValue.shown(value: "Class 5", placeholder: "Choose") == ("Class 5", false))
    }
}
