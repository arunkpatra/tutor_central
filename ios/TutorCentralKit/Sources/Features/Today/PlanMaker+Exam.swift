import Data
import Domain
import Foundation

/// The plan in exam mode (plan/phase-13-plan.md decisions 10 to 12, 17): each member's revision line from the nearest
/// exam in the window, the members on holiday, the mock made once per exam and linked again after.
extension PlanMaker {
    /// Each member's revision line for the day (the nearest exam within the window, its preparation day for the batch's
    /// date), and the members on holiday.
    func exams(for batch: PlanBatch, record: Record) -> (revisions: [UUID: RevisionLine], holidays: Set<UUID>) {
        let holidayItems = record.items.filter { $0.kind == .holiday }
        let holidays = Set(batch.members.filter {
            HolidayRules.onHoliday($0, on: batch.date, items: holidayItems, students: batch.members)
        }.map(\.id))
        var revisions: [UUID: RevisionLine] = [:]
        for student in batch.members where !holidays.contains(student.id) {
            guard let exam = SchoolItemRules.nearestExam(
                for: student, items: record.items, students: batch.members, today: batch.date, calendar: calendar
            ) else { continue }
            let context = PreparationContext(
                batch: batch.classroom, today: ExamPreparation.start(of: exam, today: batch.date, calendar: calendar),
                holidays: holidayItems, students: batch.members, calendar: calendar
            )
            let days = ExamPreparation.days(
                exam: exam, student: student, chapters: record.chapters[student.id] ?? [],
                skills: record.skills[student.id] ?? [], context: context
            )
            guard let day = days.first(where: { $0.day == batch.date }) else { continue }
            revisions[student.id] = revision(
                exam, day: day, days: days, report: record.gapReports[student.id].flatMap {
                    $0.schoolItemID == exam.id ? $0 : nil
                }
            )
        }
        return (revisions, holidays)
    }

    /// The line for one day: after the mock, the used gap report's line for that day and its weakest skills.
    private func revision(
        _ exam: SchoolItem, day: PreparationDay, days: [PreparationDay], report: GapReportContent?
    ) -> RevisionLine {
        let after = days.filter { $0.kind == .afterMock }
        let afterIndex = after.firstIndex(of: day)
        let gapLine = afterIndex.flatMap { index in
            report.flatMap { index < $0.days.count ? PlanRules.cut($0.days[index].line) : nil }
        }
        let revising = days.count {
            if case .revise = $0.kind {
                true
            } else {
                false
            }
        }
        return RevisionLine(
            itemID: exam.id, title: exam.title, subject: exam.subject ?? "", examDate: exam.date, day: day,
            gapLine: gapLine, gapSkills: report.map { GapTallies.weakest($0.bySkill, count: 6) } ?? [],
            portions: ExamPreparation.portions(exam.portions ?? exam.title),
            setNumber: afterIndex.map { revising + $0 + 1 }
        )
    }

    /// What the budget reads for the exam groups: the revision lines, the exams whose mock exists, the weakest skills.
    func examMaterial(_ batch: PlanBatch, _ record: Record) -> ExamMaterial {
        let revisions = exams(for: batch, record: record).revisions
        return ExamMaterial(
            revisions: revisions, mocksMade: Set(record.mocks.keys),
            gapSkills: revisions.compactMapValues { $0.gapSkills.isEmpty ? nil : $0.gapSkills }
        )
    }

    /// Every member is on holiday on the batch's day: no plan is made.
    public func wholeBatchOnHoliday(_ batch: PlanBatch) async -> Bool {
        guard !batch.members.isEmpty,
              let items = try? await schoolItems.items(centre: batch.centre) else { return false }
        let holidays = items.filter { $0.kind == .holiday }
        return batch.members.allSatisfy {
            HolidayRules.onHoliday($0, on: batch.date, items: holidays, students: batch.members)
        }
    }

    /// For the exams in the window that reach a member: the mock made for each, and each member's used gap report.
    func examArtefacts(
        items: [SchoolItem], members: [Student], date: Day, centre: UUID
    ) async -> (mocks: [UUID: Artefact], gapReports: [UUID: GapReportContent]) {
        let exams = items.filter { exam in
            ExamPreparation.isWithinWindow(exam, today: date, calendar: calendar)
                && members.contains { SchoolItemRules.reaches(exam, $0) }
        }
        let memberIDs = Set(members.map(\.id))
        var mocks: [UUID: Artefact] = [:]
        var reports: [UUID: GapReportContent] = [:]
        for exam in exams {
            let kept = await (try? plans.artefacts(for: exam.id, centre: centre)) ?? []
            mocks[exam.id] = kept.first { $0.kind == .mock }
            for artefact in kept where artefact.kind == .gapReport {
                guard let student = artefact.studentID, memberIDs.contains(student), reports[student] == nil,
                      case let .gapReport(content) = artefact.content, content.usedAt != nil else { continue }
                reports[student] = content
            }
        }
        return (mocks, reports)
    }

    /// On the mock day, an exam group whose mock was made before has it linked to its set's lines (made once per
    /// exam and shared).
    func linkMocks(
        into plan: PlanRecord, work: PlanWork, progress: @escaping @Sendable (Progress) async -> Void
    ) async -> PlanRecord {
        var plan = plan
        for group in plan.groups {
            guard let item = group.examItemID, let mock = work.record.mocks[item] else { continue }
            let lines = plan.items.filter { $0.groupNo == group.number && $0.kind == .practise }
            guard lines.contains(where: { $0.words == PlanRules.mockLine }),
                  !lines.contains(where: { $0.artefactID == mock.id }),
                  await (try? plans.link(items: lines.map(\.id), to: mock.id, centre: work.centre)) != nil
            else { continue }
            plan = plan.keeping(mock, link: LinePlace(group: group.number, student: nil, kind: .practise))
            cache?.keep(plan, at: now())
            await progress(.kept(mock, plan))
        }
        return plan
    }

    /// The exam group's mock, kept with its exam so the next plan links it rather than making it again.
    func mock(_ request: MockRequest, place: LinePlace, centre: UUID) async throws -> (NewArtefact, LinePlace) {
        let made = try await ai.makeMock(request, centre: centre)
        let artefact = NewArtefact(
            kind: .mock, source: .made, title: request.title, content: .mock(made.content), photoPath: nil,
            generationID: made.generationID, regeneratedFrom: nil
        )
        return (
            artefact,
            LinePlace(group: place.group, student: nil, kind: .practise, schoolItem: request.schoolItemID)
        )
    }
}
