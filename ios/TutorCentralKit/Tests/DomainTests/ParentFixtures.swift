import Foundation
@testable import Domain

/// The parents' tests' people and days (plan/phase-14-plan.md decision 28), on top of Phase 13's school samples: Dev's
/// parent Ramesh writes in Hindi and agreed; Sahil's parent Deepak in Kannada and agreed; Riya's parent Neha has not.
protocol ParentFixtures: SchoolSamples {}

extension ParentFixtures {
    var calendar: Calendar {
        DayHeading.india
    }

    /// A moment in India's calendar.
    func india(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func day(_ month: Int, _ day: Int) -> Day {
        Day(year: 2026, month: month, day: day)!
    }

    var devWithParent: Student {
        var student = dev
        student.parentName = "Ramesh Kumar"
        student.parentPhone = PhoneNumber(e164: "+919884843831")
        student.messageLanguage = .hindi
        student.consent = ConsentRecord(
            at: india(2026, 9, 20),
            phone: PhoneNumber(e164: "+919884843831")!,
            how: .whatsapp
        )
        return student
    }

    var feeMessage: FeeMessage {
        FeeMessage(
            kind: .reminder, parentName: "Ramesh Kumar", studentName: "Dev Kumar", month: Period(year: 2026, month: 10),
            amount: Money(rupees: 1000), upiID: "meera@okhdfcbank", paymentLink: nil, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
    }

    var testTomorrow: TestTomorrowMessage {
        TestTomorrowMessage(
            parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test 3",
            date: day(10, 16), portions: "Chemical reactions", revise: nil, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
    }
}
