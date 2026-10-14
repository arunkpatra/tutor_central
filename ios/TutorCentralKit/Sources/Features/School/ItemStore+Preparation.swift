import Data
import DesignSystem
import Domain
import Foundation

/// Where a Preparation row leads: Today at the batch's plan, or the mock once it is made.
public enum PreparationOpen: Hashable, Sendable {
    case today(UUID)
    case artefact(UUID)
}

/// One day of an exam's Preparation (P10-School-Item): the day column, the portion, what is made or done, the mark.
public struct PreparationRowModel: Identifiable, Hashable, Sendable {
    public let id: Day
    /// "Wed".
    public let day: String
    /// "7 Oct".
    public let date: String
    public let title: String
    /// "A set of 6 · done in today's class", "The worked example · a set of 8", "In the school's pattern · 40 marks ·
    /// mark it from a photo", "The last set from the gap report".
    public let line: String
    public let mark: PreparationRow.Mark
    public let opens: PreparationOpen?

    /// A gap report changed the day (P21-Exam-LastDaysChanged).
    public var changed: Bool {
        mark == .changed
    }
}

extension ItemStore {
    /// "Test tomorrow goes to parents on Thursday evening", from the day before the exam.
    public var testTomorrowLine: String? {
        guard testTomorrowOffered else { return nil }
        let weekday = today.weekdayLongText.split(separator: " ").first.map(String.init) ?? ""
        return "Test tomorrow goes to parents on \(weekday) evening"
    }

    /// Today is the day before the exam.
    public var testTomorrowOffered: Bool {
        guard let item, item.kind == .exam else { return false }
        return today.days(to: item.date) == 1
    }

    /// The exam's days from today to the day before it, split for its first student in a batch (the plan's split,
    /// from the day the item came), with what each day's plan made or closed.
    func loadPreparation(_ item: SchoolItem) async {
        let students = SchoolItemRules.students(for: item, in: register.activeStudents)
        guard item.kind == .exam, ExamPreparation.isWithinWindow(item, today: today, calendar: calendar),
              let student = students.first(where: { $0.classID.flatMap(register.classroom) != nil }),
              let batch = student.classID.flatMap(register.classroom) else {
            preparation = []
            lastDays = nil
            changeOpensToday = nil
            testTomorrowAsk = nil
            return
        }
        changeOpensToday = batch.id
        testTomorrowAsk = testTomorrowOffered
            ? students.first { $0.parentPhone != nil }.map { TestTomorrowAsk(item: item, student: $0) } : nil
        let centre = workspace.centre.id
        async let chapters = try? textbooks?.chapters(student: student.id)
        async let skills = try? textbooks?.skills(student: student.id)
        async let all = try? repository.items(centre: centre)
        async let mock = try? plans?.mock(for: item.id, centre: centre)
        let context = await PreparationContext(
            batch: batch, today: ExamPreparation.start(of: item, today: today, calendar: calendar),
            holidays: (all ?? []).filter { $0.kind == .holiday }, students: register.activeStudents,
            calendar: calendar
        )
        let split = await ExamPreparation.days(
            exam: item, student: student, chapters: chapters ?? [], skills: skills ?? [],
            context: context
        )
        if let mockDay = split.first(where: { $0.kind == .mock }), mockDay.day <= today, today < item.date {
            // From the mock day the page leads with the last days.
            preparation = []
            lastDays = await lastDaysModel(item, split: split, students: students, mock: mock ?? nil)
            return
        }
        lastDays = nil
        let days = split.filter { $0.day >= today && $0.kind != .exam }
        let todaysPlan = days.contains { $0.day == today }
            ? try? await plans?.plan(centre: centre, classID: batch.id, date: today) : nil
        let made = await mock
        preparation = days.map { row($0, item: item, batch: batch, plan: todaysPlan ?? nil, mock: made ?? nil) }
    }

    private func row(
        _ day: PreparationDay, item: SchoolItem, batch: Classroom, plan: PlanRecord?, mock: Artefact?
    ) -> PreparationRowModel {
        let isToday = day.day == today
        let closed = isToday && plan?.sessionID != nil
        var line: String
        var mark: PreparationRow.Mark = isToday ? .today : .none
        var opens: PreparationOpen? = isToday ? .today(batch.id) : nil
        switch day.kind {
        case .revise:
            line = (isToday ? plan.flatMap { madeLine($0, item: item) } : nil) ?? setLine(day)
        case .mock:
            let level = SchoolItemRules.students(for: item, in: register.activeStudents).compactMap(\.classLevel).max()
            line = "In the school's pattern · \(MockPattern.default(for: level).marks) marks · mark it from a photo"
            mark = isToday ? .today : .mock
            opens = mock.map { .artefact($0.id) } ?? opens
        case .afterMock:
            line = "The last set from the gap report"
        case .exam:
            line = ""
        }
        if closed {
            line = "\(plan.flatMap { madeLine($0, item: item) } ?? "The class") · done in today's class"
            mark = .done
        }
        let weekday = day.day.weekdayDayText.split(separator: " ").first.map(String.init) ?? ""
        return PreparationRowModel(
            id: day.day, day: weekday, date: day.day.shortText, title: day.title, line: line, mark: mark, opens: opens
        )
    }

    /// What the day's plan made for the exam's group: "The worked example · a set of 8", "A set of 6".
    private func madeLine(_ plan: PlanRecord, item: SchoolItem) -> String? {
        guard let group = plan.groups.first(where: { $0.examItemID == item.id }) else { return nil }
        var parts: [String] = []
        if plan.artefact(group: group.number, kind: .workedExample) != nil {
            parts.append("the worked example")
        }
        if case let .sheet(sheet)? = plan.artefact(group: group.number, kind: .sheet, homework: false)?.content {
            parts.append("a set of \(sheet.questions.count)")
        }
        guard let first = parts.first else { return nil }
        parts[0] = first.prefix(1).uppercased() + first.dropFirst()
        return parts.joined(separator: " · ")
    }

    /// A day to come: its first two skills and a set; "A set" when no chapter of the student's matched the portion
    /// (its own words are the title already).
    private func setLine(_ day: PreparationDay) -> String {
        guard !day.skillIDs.isEmpty else { return "A set" }
        return "\(day.skills.prefix(2).joined(separator: ", ")) · a set"
    }
}
