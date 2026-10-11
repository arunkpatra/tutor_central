import Domain
import Foundation

public extension FakeSchoolItemsRepository {
    nonisolated static func day(_ day: Int) -> Day {
        Day(year: 2026, month: 10, day: day) ?? Day(year: 2026, month: 1, day: 1)!
    }

    /// When the boards' message was shared: Wednesday 7 October, 15:04.
    nonisolated static let sharedAt = DayHeading.india.date(
        from: DateComponents(year: 2026, month: 10, day: 7, hour: 15, minute: 4)
    ) ?? Date()

    /// P10-School-Confirm's message.
    nonisolated static let boardMessage = """
    Dear Parents, Science Unit Test 3 for Class 8 will be held on Friday 16th Oct. Portions: Ch 1 Chemical Reactions, \
    Ch 2 Acids, Bases and Salts. Maths homework Ex 3.2 Q1 to 10 is due Monday 12th. School will remain closed 19th to \
    21st Oct for Dasara. Regards, Class Teacher, VIII B
    """

    nonisolated static let scienceTest3 = UUID(uuidString: "66666666-6666-6666-6666-666666666661")!
    nonisolated static let mathsHomework = UUID(uuidString: "66666666-6666-6666-6666-666666666662")!
    nonisolated static let dasara = UUID(uuidString: "66666666-6666-6666-6666-666666666663")!
    nonisolated static let ptm = UUID(uuidString: "66666666-6666-6666-6666-666666666664")!
    nonisolated static let devsTest = UUID(uuidString: "66666666-6666-6666-6666-666666666665")!

    /// The boards' items for the Evening batch (plan/phase-13-plan.md "Launch states"): Science unit test 3 for class 8
    /// at Vidya Niketan on Friday 16 October, the Maths homework due Monday 12, Dasara 19 to 21 October, a PTM for
    /// class 10 on Friday 9, and Dev's own Science unit test on Thursday 8.
    nonisolated static let boardItems: [SchoolItem] = {
        let vidya = FakeSchoolsRepository.vidya.id
        var devs = shared(devsTest, .exam, .student(FakeStudentsRepository.dev), "Science unit test", date: 8)
        devs.subject = "Science"
        devs.portions = "chapters 1 and 2"
        devs.source = .typed
        devs.sourceText = nil
        var ptmItem = shared(ptm, .notice, .schoolClass(school: vidya, level: .ten), "PTM, 10:00", date: 9)
        ptmItem.source = .typed
        ptmItem.sourceText = nil
        var homework = shared(
            mathsHomework, .homework, .schoolClass(school: vidya, level: .eight), "Maths Ex 3.2, Q1 to 10", date: 12
        )
        homework.subject = "Mathematics"
        var exam = shared(
            scienceTest3,
            .exam,
            .schoolClass(school: vidya, level: .eight),
            "Science unit test 3",
            date: 16
        )
        exam.subject = "Science"
        exam.portions = "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts"
        var holiday = shared(dasara, .holiday, .school(vidya), "Dasara holidays", date: 19)
        holiday.endDate = day(21)
        return [devs, ptmItem, homework, exam, holiday]
    }()

    /// An item from the boards' shared message.
    private nonisolated static func shared(
        _ id: UUID, _ kind: SchoolItemKind, _ audience: ItemAudience, _ title: String, date: Int
    ) -> SchoolItem {
        SchoolItem(
            id: id, kind: kind, audience: audience, title: title, subject: nil, date: day(date), endDate: nil,
            portions: nil, sourceText: boardMessage, photoPath: nil, source: .sharedText, receivedAt: sharedAt,
            confirmedAt: sharedAt
        )
    }
}
