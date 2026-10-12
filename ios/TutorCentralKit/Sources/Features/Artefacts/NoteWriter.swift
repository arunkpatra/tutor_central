import Data
import Domain
import Foundation

/// A student's weekly note or can-now-do written and kept for the week, as the note day's job writes it on the server
/// (Phase 18): on the phone only at a tap that asks for it (Write again, the tutor's own words), and in the fixtures'
/// note job. A young student on the ladder gets the can-now-do. The call names the student, so the gate refuses one
/// without consent.
public struct NoteWriter: Sendable {
    let workspace: Workspace
    let plans: any PlansRepository
    let ai: any AIRepository
    let calendar: Calendar

    public init(workspace: Workspace, plans: any PlansRepository, ai: any AIRepository, calendar: Calendar) {
        self.workspace = workspace
        self.plans = plans
        self.ai = ai
        self.calendar = calendar
    }

    /// The note made from the week's record and kept; `words` are the tutor's own (a weekly note only), `previous` the
    /// note it replaces. The keep runs in a task of its own: the call is paid for, so leaving the screen keeps it.
    public func write(
        _ student: Student, record: NoteRecord, week: ClosedRange<Day>, saying words: String?, replacing previous: UUID?
    ) async throws -> Artefact {
        let ladder = CanDoWeek.isLadderNote(record.student, chapters: record.chapters)
        let language = student.messageLanguage
        let said = ladder ? nil : words
        let made = try await call(record, student: student, ladder: ladder, week: week, saying: said)
        let facts = ladder
            ? CanDoWeek.facts(chapters: record.chapters, skills: record.skills, week: week, calendar: calendar).rows
            : NoteWeek.facts(record, week: week, calendar: calendar).rows
        let note = NoteContent(
            message: made.message, english: language == .english ? nil : made.english, language: language,
            weekMonday: week.lowerBound, facts: facts, generationID: made.generationID, tutorSays: said
        )
        let new = NewNote(
            studentID: student.id, kind: ladder ? .canDo : .note,
            title: ladder ? "\(student.firstName) can now do" : "\(student.firstName)'s week", content: note,
            regeneratedFrom: previous
        )
        let (plans, centre) = (plans, workspace.centre.id)
        return try await Task { try await plans.keepNote(new, centre: centre) }.value
    }

    private func call(
        _ record: NoteRecord, student: Student, ladder: Bool, week: ClosedRange<Day>, saying words: String?
    ) async throws(APIFailure) -> MadeMessage {
        let tutor = workspace.profile.displayName ?? workspace.centre.name
        let level = student.classLevel ?? .messageFallback
        let language = student.messageLanguage
        if ladder {
            let facts = CanDoWeek.facts(
                chapters: record.chapters,
                skills: record.skills,
                week: week,
                calendar: calendar
            )
            return try await ai.makeCanDo(
                CanDoRequest(
                    studentID: student.id, studentName: student.name, parentName: student.parentName, tutorName: tutor,
                    centreName: workspace.centre.name, classLevel: level, language: language, facts: facts
                ),
                centre: workspace.centre.id
            )
        }
        let facts = NoteWeek.facts(record, week: week, calendar: calendar)
        let request = NoteRequest(
            studentID: student.id, studentName: student.name, parentName: student.parentName, tutorName: tutor,
            centreName: workspace.centre.name, classLevel: level, language: language, weekMonday: week.lowerBound,
            week: NoteRequest.Week(facts)
        )
        return try await ai.makeNote(words.map(request.saying) ?? request, centre: workspace.centre.id)
    }
}
