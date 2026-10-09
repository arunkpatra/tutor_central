import Domain
import Foundation
import Testing
import UserNotifications
@testable import Data

@MainActor struct NotificationClientTests {
    let reminder = Reminder(
        id: "class-x-2026-10-07", kind: .classMeeting, title: "Class 10 Maths at 17:00",
        body: "In 15 minutes · 6 students. Tap to mark attendance.",
        fireAt: DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 45))
            ?? Date(),
        link: "tutorcentral://attendance?date=2026-10-07&class=x"
    )

    @Test func theFakeRecordsTheAskAndThePlan() async {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        #expect(await center.permission() == .notAsked)
        #expect(await center.requestPermission())
        #expect(center.asked == 1)
        #expect(await center.permission() == .allowed)
        await center.replace(with: [reminder])
        #expect(await center.pending() == [reminder] && center.replacements == 1)
        await center.removeAll()
        #expect(await center.pending().isEmpty)
        let refusing = FakeNotificationCenter(permission: .notAsked, allowOnAsk: false)
        #expect(await refusing.requestPermission() == false)
        #expect(await refusing.permission() == .refused)
    }

    @Test func aRequestCarriesTheTimeTheWordsAndTheLink() throws {
        let request = UNClient.request(for: reminder, calendar: DayHeading.india)
        #expect(request.identifier == "class-x-2026-10-07")
        #expect(request.content.title == "Class 10 Maths at 17:00" && request.content.body == reminder.body)
        #expect(request.content.userInfo["link"] as? String == reminder.link)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(trigger.dateComponents.hour == 16 && trigger.dateComponents.minute == 45)
        #expect(trigger.dateComponents.day == 7 && trigger.dateComponents.month == 10)
        #expect(!trigger.repeats)
    }

    @Test func aTapBeforeTheHandlerIsDeliveredOnce() {
        let delegate = NotificationDelegate()
        delegate.open(URL(string: "tutorcentral://today"))
        var opened: [URL] = []
        delegate.onOpen = { opened.append($0) }
        #expect(opened.map(\.absoluteString) == ["tutorcentral://today"])
        delegate.onOpen = { opened.append($0) }
        #expect(opened.count == 1)
        delegate.open(URL(string: "tutorcentral://fees"))
        #expect(opened.map(\.absoluteString) == ["tutorcentral://today", "tutorcentral://fees"])
    }
}
