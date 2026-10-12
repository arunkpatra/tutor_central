import Data
import Domain
import Foundation

/// The preview in exam mode (plan/phase-13-plan.md decisions 10 to 12, 17), as the server's plan reads it: each
/// member's
/// revision line from the nearest exam in the window, and the members on holiday.
extension PlanPreview {
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
            // The test day itself has no revision: the student is back in their level group (review Important 1).
            guard let day = days.first(where: { $0.day == batch.date }), day.kind != .exam else { continue }
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

    /// For the exams in the window that reach a member: each member's used gap report.
    func gapReports(
        items: [SchoolItem],
        members: [Student],
        date: Day,
        centre: UUID
    ) async -> [UUID: GapReportContent] {
        let exams = items.filter { exam in
            ExamPreparation.isWithinWindow(exam, today: date, calendar: calendar)
                && members.contains { SchoolItemRules.reaches(exam, $0) }
        }
        let memberIDs = Set(members.map(\.id))
        var reports: [UUID: GapReportContent] = [:]
        for exam in exams {
            let kept = await (try? plans.artefacts(for: exam.id, centre: centre)) ?? []
            for artefact in kept where artefact.kind == .gapReport {
                guard let student = artefact.studentID, memberIDs.contains(student), reports[student] == nil,
                      case let .gapReport(content) = artefact.content, content.usedAt != nil else { continue }
                reports[student] = content
            }
        }
        return reports
    }
}
