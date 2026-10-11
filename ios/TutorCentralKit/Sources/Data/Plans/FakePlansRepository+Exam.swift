import Domain
import Foundation

public extension FakePlansRepository {
    /// The boards' mock (P10-Mock): Dev's own Science unit test on Thursday 8 October, chapters 1 and 2, in the default
    /// pattern for class 8, made at 16:40 on Wednesday 7 October, kept with the exam and no plan.
    nonisolated static let boardMockID = UUID(uuidString: "abababab-0000-0000-0013-000000000001")!

    nonisolated static var boardMock: Artefact {
        let request = MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test", portions: ["chapters 1 and 2"],
            pattern: .default(for: .eight), schoolItemID: FakeSchoolItemsRepository.devsTest
        )
        let madeAt = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 16, minute: 40))
            ?? Date()
        return Artefact(
            id: boardMockID, kind: .mock, source: .made, title: request.title, content: .mock(AISamples.mock(request)),
            photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: madeAt,
            generationID: UUID(uuidString: "abababab-0000-0000-0013-000000000002"), schoolItemID: request.schoolItemID
        )
    }
}

public extension FakePlansRepository {
    /// The last days' boards (P10-School-Exam-LastDays, P10-GapReport): Science unit test 3's mock in the default
    /// pattern for class 8, made on Wednesday 14 October at 16:30 and kept with the exam.
    nonisolated static let examMockID = UUID(uuidString: "abababab-0000-0000-0013-000000000003")!
    nonisolated static let devGapReportID = UUID(uuidString: "abababab-0000-0000-0013-000000000004")!

    nonisolated static var examMockContent: MockContent {
        AISamples.mock(MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test 3",
            portions: ["Chemical reactions", "Acids, bases and salts"], pattern: .default(for: .eight),
            schoolItemID: FakeSchoolItemsRepository.scienceTest3
        ))
    }

    nonisolated static var lastDaysArtefacts: [Artefact] {
        let at = { (hour: Int, minute: Int) in
            DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 14, hour: hour, minute: minute))
                ?? Date()
        }
        let item = FakeSchoolItemsRepository.scienceTest3
        let mock = Artefact(
            id: examMockID, kind: .mock, source: .made, title: "Science unit test 3",
            content: .mock(examMockContent), photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil,
            madeAt: at(16, 30), generationID: UUID(uuidString: "abababab-0000-0000-0013-000000000005"),
            schoolItemID: item
        )
        let devMark = FakeRecordRepository.lastDaysMarks[0]
        let report = GapReportContent(
            summary: AISamples.gapSummary,
            bySkill: GapTallies.bySkill(
                CheckResult(questions: devMark.questions ?? [], summary: ""), mock: examMockContent
            ),
            days: AISamples.gapDays, usedAt: nil, score: devMark.score, max: devMark.max, schoolItemID: item
        )
        let gap = Artefact(
            id: devGapReportID, kind: .gapReport, source: .made, title: "After the mock",
            content: .gapReport(report), photoPath: nil, studentID: FakeStudentsRepository.dev, planID: nil,
            regeneratedFrom: nil, madeAt: at(18, 50), generationID: nil, schoolItemID: item
        )
        return [mock, gap]
    }
}

public extension FakeRecordRepository {
    /// Dev's mock marked with the balancing and types-of-reaction questions short, Meher's with every mark.
    nonisolated static var lastDaysMarks: [MarkRecord] {
        let questions = FakePlansRepository.examMockContent.sections.flatMap(\.questions)
        func mark(_ student: UUID, short: Bool, id: String) -> MarkRecord {
            let marks = questions.map { question in
                let lost = short && ["Balance a chemical equation", "Name the types of reactions"]
                    .contains(question.skill)
                return CheckResult.QuestionMark(
                    number: question.number, text: question.text,
                    note: lost ? "Changed the formulas instead of the front numbers" : "",
                    marks: lost ? question.marks / 3 : question.marks, of: question.marks, changedFrom: nil
                )
            }
            return MarkRecord(
                id: UUID(uuidString: id) ?? UUID(), studentID: student, subject: "Science",
                test: "Science unit test 3 · mock", date: Day(year: 2026, month: 10, day: 14) ?? Day(
                    year: 2026,
                    month: 1,
                    day: 1
                )!,
                score: marks.reduce(0) { $0 + $1.marks }, max: FakePlansRepository.examMockContent.marks,
                photoPath: nil, schoolItemID: FakeSchoolItemsRepository.scienceTest3,
                artefactID: FakePlansRepository.examMockID, questions: marks
            )
        }
        return [
            mark(FakeStudentsRepository.dev, short: true, id: "abababab-0000-0000-0013-000000000006"),
            mark(FakeStudentsRepository.meher, short: false, id: "abababab-0000-0000-0013-000000000007"),
        ]
    }
}

public extension FakeRecordRepository {
    /// Hemanth's marks (P13-Student-Marks): a class test and unit test 1 in Mathematics, unit test 2 below his usual,
    /// then a mock (the board's figures are illustrative).
    nonisolated static var hemanthsMarks: [MarkRecord] {
        let day = { (month: Int, day: Int) in
            Day(year: 2026, month: month, day: day) ?? Day(year: 2026, month: 1, day: 1)!
        }
        let mark = { (index: Int, test: String, date: Day, score: Int, max: Int) in
            MarkRecord(
                id: UUID(uuidString: "abababab-0000-0000-0013-00000000010\(index)") ?? UUID(),
                studentID: FakeStudentsRepository.hemanth, subject: "Mathematics", test: test, date: date,
                score: score, max: max, photoPath: nil, schoolItemID: nil,
                artefactID: index == 3 ? FakePlansRepository.examMockID : nil, questions: nil
            )
        }
        return [
            mark(0, "Class test", day(7, 20), 18, 25), mark(1, "Unit test 1", day(8, 24), 19, 25),
            mark(2, "Unit test 2", day(9, 28), 14, 25), mark(3, "Maths unit test 3 · mock", day(10, 6), 26, 40),
        ]
    }
}
