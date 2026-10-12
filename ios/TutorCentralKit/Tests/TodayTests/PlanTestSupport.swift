import Data
import Domain
import Foundation
import Students
@testable import Today

/// What the plan's tests share: the boards' moments, the centre, the Evening batch's register and members, a batch's
/// session closed today.
enum PlanTest {
    static let centre = FakeCentreRepository.meeraWorkspace.centre.id
    static let evening = FakeClassesRepository.evening
    static let wednesday = Day(year: 2026, month: 10, day: 7)!
    static let at1635 = at(7, 16, 35)
    static let at1840 = at(7, 18, 40)
    static let saturday0930 = at(10, 9, 30)
    static let members = FakeStudentsRepository.eveningSeed.filter { $0.classID == FakeClassesRepository.evening.id }

    static func batch(_ members: [Student], classroom: Classroom = evening, on date: Day = wednesday) -> PlanBatch {
        PlanBatch(classroom: classroom, members: members, date: date, centre: centre)
    }

    static func at(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    @MainActor static func register(now: Date = at1635) async -> RegisterStore {
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            students: FakeStudentsRepository(students: FakeStudentsRepository.eveningSeed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.load()
        return register
    }

    /// The seed with the Evening batch closed today at 18:32.
    static let eveningClosedToday: [AttendanceSession] = {
        let marks = Dictionary(uniqueKeysWithValues: members.map { ($0.id, AttendanceStatus.present) })
        let closed = AttendanceSession(
            id: UUID(), classID: evening.id, date: wednesday, savedAt: at(7, 18, 32), marks: marks,
            closedAt: at(7, 18, 32)
        )
        return [closed] + FakeAttendanceRepository.seed
    }()

    /// Riya's first skill renamed so her teach skill names the fraction bar.
    @MainActor static func textbooksWithRiyasFractions() -> FakeTextbooksRepository {
        let repo = FakeTextbooksRepository.evening()
        if var skills = repo.skillsByStudent[FakeStudentsRepository.riya], !skills.isEmpty {
            skills[0].name = "Compare simple fractions"
            repo.skillsByStudent[FakeStudentsRepository.riya] = skills
        }
        return repo
    }

    @MainActor static func preview(
        plans: FakePlansRepository, textbooks: FakeTextbooksRepository = .evening(),
        attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed),
        cache: PlanCache? = nil, now: Date = at1635, items: [SchoolItem] = [],
        schoolItems: FakeSchoolItemsRepository? = nil
    ) -> PlanPreview {
        PlanPreview(
            plans: plans, textbooks: textbooks, attendance: attendance,
            schoolItems: schoolItems ?? FakeSchoolItemsRepository(items: items, now: now), cache: cache, now: { now },
            calendar: DayHeading.india
        )
    }

    /// The server's plan job done in place: a request writes the rules' plan for the batch with its material
    /// (`FakePlansRepository.serve`) and the job is done.
    @MainActor static func serving(
        _ plans: FakePlansRepository, preview: PlanPreview, now: Date = at1635,
        students: [Student] = FakeStudentsRepository.eveningSeed,
        classes: [Classroom] = FakeClassesRepository.withEvening
    ) -> FakeJobsRepository {
        let jobs = FakeJobsRepository(now: { now })
        jobs.onPlanRequest = { classID, date, choices in
            let members = students.filter { $0.classID == classID && $0.archivedAt == nil }
            let pairs = members.compactMap { member in member.classLevel.map { (member.id, $0) } }
            let levels = Dictionary(pairs) { first, _ in first }
            guard let classroom = classes.first(where: { $0.id == classID }),
                  let draft = try? await preview.draft(
                      batch(members, classroom: classroom, on: date),
                      choices: choices
                  ),
                  await (try? plans.serve(draft, levels: levels, material: true, centre: centre)) != nil
            else { return .failed }
            return .done
        }
        return jobs
    }
}
