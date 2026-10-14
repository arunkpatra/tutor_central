import Data
import Domain
import Foundation
import School
import Students
import Testing

/// The exam's last days (P10-School-Exam-LastDays; plan/phase-13-plan.md decision 22): from the mock day the page leads
/// with Today (the mock, Mark from a photo), Marked (each student's score and weakest skill), The last two days.
@MainActor struct LastDaysTests {
    nonisolated static let wednesday14 = DayHeading.india.date(from: DateComponents(
        year: 2026, month: 10, day: 14, hour: 16, minute: 35
    ))!
    static let exam = FakeSchoolItemsRepository.scienceTest3
    static let centre = FakeCentreRepository.meeraWorkspace.centre.id

    struct World {
        let plans: FakePlansRepository
        let record: FakeRecordRepository
        let mock: MockContent?
    }

    /// The exam's mock (unless not made), Dev's mark with question 1 wrong, Meher's with every mark.
    func world(mockMade: Bool = true, reportsUsed: Bool = false) async throws -> World {
        let plans = FakePlansRepository(now: Self.wednesday14)
        guard mockMade else { return World(plans: plans, record: FakeRecordRepository(marks: []), mock: nil) }
        let request = MockRequest(
            classLevel: .eight, subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"],
            pattern: .default(for: .eight), schoolItemID: Self.exam
        )
        let made = try await FakeAIRepository().makeMock(request, centre: Self.centre)
        let mock = try await plans.keep(
            NewArtefact(
                kind: .mock, source: .made, title: request.title, content: .mock(made.content), photoPath: nil,
                generationID: made.generationID, regeneratedFrom: nil
            ),
            to: ArtefactLink(item: Self.exam, student: nil), centre: Self.centre
        )
        let questions = made.content.sections.flatMap(\.questions)
        func mark(_ student: UUID, wrongFirst: Bool) -> MarkRecord {
            let marks = questions.map { question in
                CheckResult.QuestionMark(
                    number: question.number, text: question.text, note: "",
                    marks: wrongFirst && question.number == 1 ? 0 : question.marks, of: question.marks,
                    changedFrom: nil
                )
            }
            return MarkRecord(
                id: UUID(), studentID: student, subject: "Science", test: "Science unit test 3 · mock",
                date: Day(year: 2026, month: 10, day: 14)!, score: marks.reduce(0) { $0 + $1.marks },
                max: made.content.marks, photoPath: nil, schoolItemID: Self.exam, artefactID: mock.id,
                questions: marks
            )
        }
        if reportsUsed {
            try await keepUsedReports(plans)
        }
        let record = FakeRecordRepository(marks: [
            mark(FakeStudentsRepository.dev, wrongFirst: true), mark(FakeStudentsRepository.meher, wrongFirst: false),
        ])
        return World(plans: plans, record: record, mock: made.content)
    }

    /// Dev's and Meher's gap reports, used, each with a line for Thursday.
    func keepUsedReports(_ plans: FakePlansRepository) async throws {
        for (student, line) in [
            (FakeStudentsRepository.dev, "Balancing equations, the worked example and a set"),
            (FakeStudentsRepository.meher, "A short revision set"),
        ] {
            let content = GapReportContent(
                summary: "x", bySkill: [], days: [GapReportContent.DayPlan(title: "Thursday", line: line)],
                usedAt: Self.wednesday14, score: 0, max: 40, schoolItemID: Self.exam
            )
            _ = try await plans.keep(
                NewArtefact(
                    kind: .gapReport, source: .made, title: "After the mock", content: .gapReport(content),
                    photoPath: nil, generationID: nil, regeneratedFrom: nil
                ),
                to: ArtefactLink(item: Self.exam, student: student), centre: Self.centre
            )
        }
    }

    /// The Evening batch; Dev's and Meher's parents agreed, Nikhil's not.
    func register() async -> RegisterStore {
        let students = FakeStudentsRepository.eveningSeed.map { student in
            guard [FakeStudentsRepository.dev, FakeStudentsRepository.meher].contains(student.id),
                  let phone = student.parentPhone else { return student }
            var changed = student
            changed.consent = ConsentRecord(at: Self.wednesday14, phone: phone, how: .inPerson)
            return changed
        }
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil,
            now: { Self.wednesday14 }
        )
        await register.load()
        return register
    }

    func page(_ world: World, jobs: FakeJobsRepository? = nil) async -> ItemStore {
        let store = await ItemStore(
            itemID: Self.exam, workspace: FakeCentreRepository.meeraWorkspace,
            items: FakeSchoolItemsRepository(items: SchoolFixtures.boardItems), register: register(),
            schools: FakeSchoolsRepository(), photos: FakePhotoStore(), now: { Self.wednesday14 },
            calendar: DayHeading.india, online: { true }, textbooks: FakeTextbooksRepository.evening(),
            plans: world.plans, record: world.record
        )
        store.jobs = jobs
        await store.load()
        return store
    }

    @Test func twoDaysBeforeThePageLeadsWithTheMockAndTheMarkedRows() async throws {
        let world = try await world()
        let page = await page(world)
        let days = try #require(page.lastDays)
        #expect(days.todayTitle == "Today, Wednesday" && days.mockState == .ready)
        #expect(days.mockTitle == "The mock, for Dev, Meher and Nikhil")
        #expect(days.mockLine == "In the school's pattern · 40 marks · 60 minutes")
        let mock = try #require(world.mock)
        let firstSkill = try #require(mock.sections.first?.questions.first?.skill)
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(dev.line
            .hasPrefix("\(mock.marks - (mock.sections.first?.questions.first?.marks ?? 0)) of 40 · \(firstSkill) "))
        #expect(days.marked.first { $0.id == FakeStudentsRepository.meher }?.line == "40 of 40 · all skills secure")
        #expect(days.marked.first { $0.id == FakeStudentsRepository.nikhil }?.line == "Not marked yet")
        #expect(days.marked.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        #expect(page.preparation.isEmpty)
        // The page leads with the last days: no Who, no portions line (P10-School-Exam-LastDays).
        #expect(page.who.isEmpty && page.hero?.portionsLine == nil)
    }

    @Test func aStudentWithoutConsentCannotBeMarkedOrReported() async throws {
        let days = try #require(try await page(world()).lastDays)
        let nikhil = try #require(days.marked.first { $0.id == FakeStudentsRepository.nikhil })
        #expect(!nikhil.canMark && !nikhil.canReport)
        #expect(nikhil.consentLine == "Marking waits for Arup's consent")
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(dev.canMark && dev.canReport && dev.consentLine == nil)
    }

    @Test func theLastTwoDaysReadTheUsedReportsLinesPerStudent() async throws {
        let days = try #require(try await page(world(reportsUsed: true)).lastDays)
        #expect(days.lastDays.map(\.date) == ["15 Oct", "16 Oct"])
        #expect(days.lastDays.first?.title == "What the mocks showed")
        #expect(days.lastDays.first?.line
            == "Dev: balancing equations, the worked example and a set · Meher: a short revision set")
        #expect(days.lastDays.last?.title == "The test")
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(dev.gapReportID != nil)
    }

    @Test func beforeTheMockIsMadeTheRowSaysSo() async throws {
        let days = try #require(try await page(world(mockMade: false)).lastDays)
        #expect(days.mockState == .notMade && days.mockID == nil)
        #expect(days.mockLine == "The mock is made with Wednesday's plan")
        #expect(days.marked.allSatisfy { $0.line == "Not marked yet" })
        #expect(days.lastDays.first?.line == "The last set from each gap report, once the mocks are marked")
    }

    // MARK: The exam's job (D106, P21-Exam-*)

    func jobs(_ status: ExamJobStatus?) -> FakeJobsRepository {
        let jobs = FakeJobsRepository()
        jobs.examJobs[Self.exam] = status
        return jobs
    }

    @Test func theMockRowFollowsTheJob() async throws {
        let live = ExamJobStatus(state: .waiting, at: "mock", mockFailed: false)
        let making = try #require(try await page(world(mockMade: false), jobs: jobs(live)).lastDays)
        #expect(making.mockState == .making)
        #expect(making.mockLine == "In the school's pattern · 40 marks · usually ready in a minute")
        let failed = ExamJobStatus(state: .waiting, at: "marks", mockFailed: true)
        let notMade = try #require(try await page(world(mockMade: false), jobs: jobs(failed)).lastDays)
        #expect(notMade.mockState == .failed && notMade.mockLine == LastDaysModel.mockFailedLine)
        let made = try #require(try await page(world(), jobs: jobs(failed)).lastDays)
        #expect(made.mockState == .ready)
        // Before the mock day the job's wait is not the mock being made.
        let before = try ItemStore.mockState(
            mock: nil, job: live, today: #require(Day(year: 2026, month: 10, day: 13)),
            mockDay: #require(Day(year: 2026, month: 10, day: 14))
        )
        #expect(before == .notMade)
    }

    @Test func aFailedMockOffersTryAgainWhichAsksTheJob() async throws {
        let jobs = jobs(ExamJobStatus(state: .waiting, at: "marks", mockFailed: true))
        let page = try await page(world(mockMade: false), jobs: jobs)
        #expect(page.lastDays?.mockState == .failed)
        jobs.examJobs[Self.exam] = ExamJobStatus(state: .running, at: "mock", mockFailed: false)
        await page.tryAgain()
        #expect(jobs.examPrepRequests == [Self.exam])
        #expect(page.lastDays?.mockState == .making)
    }

    /// The review of Phase 21 (R-app-1): Try again marks the job's step woken (0058); the page shows Being made at once
    /// and
    /// reads itself again while it is made, so the row moves on without the tutor leaving the page.
    @Test func tryAgainShowsBeingMadeAndReadsAgainWhileItIsMade() async throws {
        let jobs = jobs(ExamJobStatus(state: .waiting, at: "marks", mockFailed: true))
        let page = try await page(world(mockMade: false), jobs: jobs)
        page.followEvery = .milliseconds(20)
        await page.tryAgain()
        #expect(page.lastDays?.mockState == .making)
        // The job ran and could not make it again: the page reads that by itself.
        jobs.examJobs[Self.exam] = ExamJobStatus(state: .waiting, at: "marks", mockFailed: true)
        try await Task.sleep(for: .milliseconds(300))
        #expect(page.lastDays?.mockState == .failed)
    }

    @Test func aFailedTryAgainSaysSoAndKeepsTheRow() async throws {
        let jobs = jobs(ExamJobStatus(state: .waiting, at: "marks", mockFailed: true))
        let page = try await page(world(mockMade: false), jobs: jobs)
        jobs.failure = URLError(.notConnectedToInternet)
        await page.tryAgain()
        #expect(page.message == "That didn't go through. Check your connection and try again.")
        #expect(page.lastDays?.mockState == .failed)
    }

    @Test func aMarkedStudentWithoutAReportIsWorking() async throws {
        let live = ExamJobStatus(state: .waiting, at: "marks", mockFailed: false)
        let days = try #require(try await page(world(), jobs: jobs(live)).lastDays)
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(dev.working && !dev.canReport)
        #expect(dev.line.hasSuffix(" of 40 · working out the last two days"))
        let nikhil = try #require(days.marked.first { $0.id == FakeStudentsRepository.nikhil })
        #expect(!nikhil.working && nikhil.line == "Not marked yet")
        #expect(days.lastDays.first?.line == "Dev and Meher's lines follow once their marks are read")
        // With no live job nothing is being worked out.
        let done = try #require(try await page(world(), jobs: jobs(nil)).lastDays)
        #expect(done.marked.allSatisfy { !$0.working })
        #expect(done.lastDays.first?.line == "The last set from the gap report")
    }

    /// Hand run 5: a report the job could not make leaves the row as with no job, its report offered on the phone.
    @Test func aReportTheJobCouldNotMakeIsNotWorking() async throws {
        let live = ExamJobStatus(state: .waiting, at: "marks", mockFailed: false, notMade: [FakeStudentsRepository.dev])
        let days = try #require(try await page(world(), jobs: jobs(live)).lastDays)
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(!dev.working && dev.canReport)
        #expect(!dev.line.contains("working out"))
        #expect(days.lastDays.first?.line.hasPrefix("Meher's lines follow") == true)
    }

    /// Hand run 6: with no mock kept the job makes no report, so a marked student is not shown as worked on.
    @Test func noMockNoReportWorkedOn() async throws {
        let failed = ExamJobStatus(state: .waiting, at: "marks", mockFailed: true)
        let marked = try await world()
        let noMock = World(plans: FakePlansRepository(now: Self.wednesday14), record: marked.record, mock: nil)
        let days = try #require(try await page(noMock, jobs: jobs(failed)).lastDays)
        #expect(days.mockState == .failed)
        #expect(days.marked.allSatisfy { !$0.working })
    }

    @Test func aUsedReportMarksTheDayChanged() async throws {
        let live = ExamJobStatus(state: .waiting, at: "marks", mockFailed: false)
        let days = try #require(try await page(world(reportsUsed: true), jobs: jobs(live)).lastDays)
        #expect(days.changed && days.lastDays.first?.changed == true)
        let dev = try #require(days.marked.first { $0.id == FakeStudentsRepository.dev })
        #expect(!dev.working && dev.line.hasSuffix(" · the last two days changed"))
        #expect(days.lastDays.last?.changed == false)
    }
}
