import Foundation
import Testing
@testable import AppShell

struct DeepLinkTests {
    func link(_ text: String) throws -> DeepLink? {
        try DeepLink(url: #require(URL(string: text)))
    }

    @Test func theFiveLinksOfTheInformationArchitecture() throws {
        let id = UUID()
        #expect(try link("tutorcentral://today") == .today)
        #expect(try link("tutorcentral://student/\(id)") == .student(id))
        #expect(try link("tutorcentral://fees?month=2026-10") == .fees(month: "2026-10"))
        #expect(try link("tutorcentral://fees") == .fees(month: nil))
        #expect(try link("tutorcentral://attendance?date=2026-10-07&class=\(id)") == .attendance(
            date: "2026-10-07",
            classID: id
        ))
        #expect(try link("tutorcentral://event/\(id)") == .event(id))
        #expect(try link("tutorcentral://auth-callback?code=x") == .authCallback)
    }

    @Test func anythingElseIsNil() throws {
        for text in [
            "https://example.com/today",
            "tutorcentral://",
            "tutorcentral://student/not-a-uuid",
            "tutorcentral://settings",
        ] {
            #expect(try link(text) == nil, "\(text)")
        }
    }

    @Test func eachLinkNamesItsTab() {
        #expect(DeepLink.today.tab == .today && DeepLink.student(UUID()).tab == .students)
        #expect(DeepLink.fees(month: nil).tab == .fees && DeepLink.attendance(date: nil, classID: nil)
            .tab == .attendance)
        #expect(DeepLink.event(UUID()).tab == .more && DeepLink.authCallback.tab == .today)
    }
}
