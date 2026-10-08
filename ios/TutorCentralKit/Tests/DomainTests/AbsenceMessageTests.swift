import Foundation
import Testing
@testable import Domain

struct AbsenceMessageTests {
    let day = Day(year: 2026, month: 10, day: 7)!

    @Test func theMessageAsTheBoardWritesIt() {
        let text = AbsenceMessage(
            parentName: "Lakshmi Reddy", studentName: "Hemanth Reddy", className: "Class 10 Maths", day: day,
            today: day,
            tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        ).text
        #expect(text == """
        Hello Lakshmi, Hemanth was absent from Class 10 Maths today, Wednesday 7 October. \
        Please let me know if everything is all right.

        Meera Nair
        Bright Minds Tuition
        """)
    }

    @Test func withoutAParentNameAClassOrATutorName() throws {
        let past = try #require(Day(year: 2026, month: 10, day: 5))
        let text = AbsenceMessage(
            parentName: nil,
            studentName: "Sahil Verma",
            className: nil,
            day: past,
            today: day,
            tutorName: nil,
            centreName: "Bright Minds Tuition"
        ).text
        #expect(text == """
        Hello, Sahil was absent from class on Monday 5 October. Please let me know if everything is all right.

        Bright Minds Tuition
        """)
    }

    @Test func theLinkCarriesTheMessageEncoded() throws {
        let phone = try #require(PhoneNumber(e164: "+919380260871"))
        let url = AbsenceMessage.whatsAppURL(phone: phone, text: "Hello Lakshmi, Hemanth & co.")
        #expect(url.absoluteString == "https://wa.me/919380260871?text=Hello%20Lakshmi%2C%20Hemanth%20%26%20co.")
    }
}
