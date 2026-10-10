import Foundation
import Testing
@testable import Domain

struct ConsentMessageTests {
    @Test func theConsentMessageFollowsTheBoardAndTheGender() {
        let her = ConsentMessage.text(
            parentFirstName: "Neha",
            childFirstName: "Riya",
            gender: .female,
            tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
        #expect(her.hasPrefix("Hello Neha, I use Tutor Central to plan Riya's classes and keep her progress."))
        #expect(her.contains("her name, class, marks and work may be read by an AI service (Claude, by Anthropic)."))
        #expect(her.contains("Please reply YES if you agree. Thank you."))
        #expect(her.hasSuffix("Meera Nair\nBright Minds Tuition"))
        #expect(ConsentMessage.text(
            parentFirstName: "Ramesh",
            childFirstName: "Dev",
            gender: .male,
            tutorName: "M",
            centreName: nil
        ).contains("keep his progress"))
        #expect(ConsentMessage.text(
            parentFirstName: "A",
            childFirstName: "B",
            gender: nil,
            tutorName: "M",
            centreName: nil
        ).contains("keep their progress"))
        #expect(ConsentMessage.text(
            parentFirstName: "A",
            childFirstName: "B",
            gender: .other,
            tutorName: "M",
            centreName: nil
        ).hasSuffix("Thank you.\n\nM"))
    }
}
