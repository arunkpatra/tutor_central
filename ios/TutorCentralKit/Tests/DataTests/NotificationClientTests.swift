import Foundation
import Testing
@testable import Data

@MainActor struct NotificationClientTests {
    @Test func theFakeRecordsTheAskAndTheRemovals() async {
        let center = FakeNotificationCenter(permission: .notAsked, allowOnAsk: true)
        #expect(await center.permission() == .notAsked)
        #expect(await center.requestPermission())
        #expect(center.asked == 1)
        #expect(await center.permission() == .allowed)
        await center.removePending()
        await center.removeAll()
        #expect(center.pendingRemoved == 1 && center.allRemoved == 1)
        let refusing = FakeNotificationCenter(permission: .notAsked, allowOnAsk: false)
        #expect(await refusing.requestPermission() == false)
        #expect(await refusing.permission() == .refused)
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

    /// Build 13 aborted when a tester tapped a reminder: the async `didReceive` finished on a background thread and
    /// UIKit
    /// heard the tap was handled there (its state restoration asserts the main thread). Wherever the tap arrives, the
    /// link opens and the completion runs on the main thread.
    @Test func aTappedReminderFinishesOnTheMainThreadWhereverItArrives() async {
        let delegate = NotificationDelegate()
        var opened: [URL] = []
        delegate.onOpen = { opened.append($0) }
        let finishedOnMain = await withCheckedContinuation { (done: CheckedContinuation<Bool, Never>) in
            Task.detached {
                delegate.received(
                    URL(string: "tutorcentral://attendance"),
                    then: { done.resume(returning: Thread.isMainThread) }
                )
            }
        }
        #expect(finishedOnMain)
        #expect(opened.map(\.absoluteString) == ["tutorcentral://attendance"])
    }

    @Test func aReminderCarriesItsLinkInUserInfo() {
        #expect(NotificationDelegate.link(from: ["link": "tutorcentral://fees"])?
            .absoluteString == "tutorcentral://fees")
        #expect(NotificationDelegate.link(from: [:]) == nil)
    }

    /// A push carries its link beside `aps` (api/src/push/payload.ts); one with none opens Today.
    @Test func aPushOpensItsLinkOrToday() {
        let alert: [AnyHashable: Any] = ["aps": ["alert": ["title": "t", "body": "b"]], "link": "tutorcentral://plan"]
        #expect(NotificationDelegate.link(from: alert)?.absoluteString == "tutorcentral://plan")
        let bare: [AnyHashable: Any] = ["aps": ["alert": ["title": "t", "body": "b"]]]
        #expect(NotificationDelegate.link(from: bare)?.absoluteString == "tutorcentral://today")
    }
}
