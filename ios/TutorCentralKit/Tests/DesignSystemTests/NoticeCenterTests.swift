import Testing
@testable import DesignSystem

/// U33: a failed or refused write is the system alert. The app's words become its title (the first sentence, without
/// its full stop) and its message (the rest); the frontmost screen shows it.
@MainActor struct NoticeCenterTests {
    @Test func theFirstSentenceIsTheTitleAndTheRestTheMessage() {
        let split = NoticeCenter
            .split("Attendance wasn't saved. Check your connection and try again. Your marks are still here.")
        #expect(split.title == "Attendance wasn't saved")
        #expect(split.message == "Check your connection and try again. Your marks are still here.")
        #expect(NoticeCenter.split("No camera on this device.") == ("No camera on this device", ""))
        #expect(NoticeCenter.split("One at a time: the last one is still being written.").title
            == "One at a time: the last one is still being written")
    }

    @Test func aNoticeWithRetryOffersTryAgainBesideOK() {
        let notices = NoticeCenter()
        var retried = false
        notices.show("Couldn't save attendance. Check your connection and try again.", retry: { retried = true })
        #expect(notices.current?.title == "Couldn't save attendance")
        #expect(notices.current?.cancel == "OK" && notices.current?.action?.label == "Try Again")
        notices.current?.action?.run()
        #expect(retried)
        notices.dismiss()
        #expect(notices.current == nil)
    }

    @Test func theRootShowsItOnlyWhenNoSheetIsUp() {
        let notices = NoticeCenter()
        notices.show("This event was deleted. The schedule shows what is still on it.")
        #expect(notices.showsOnRoot)
        notices.sheetAppeared()
        #expect(!notices.showsOnRoot && notices.showsOnSheet)
        notices.sheetGone()
        #expect(notices.showsOnRoot)
    }

    @Test func aCameraThatIsOffOffersNotNowAndOpenSettings() {
        let notices = NoticeCenter()
        notices.cameraOff(to: "photograph a register", otherwise: "You can also choose a photo you already have.")
        #expect(notices.current?.title == "The camera is off for Tutor Central")
        #expect(notices.current?.message
            == "Turn it on in Settings to photograph a register. You can also choose a photo you already have.")
        #expect(notices.current?.cancel == "Not Now" && notices.current?.action?.label == "Open Settings")
    }
}
