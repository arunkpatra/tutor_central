import Data
import Domain
import Foundation

extension NoteDayStore {
    struct WeekRead {
        let rows: [NoteRowModel]
        /// By student: their parent's suggested messages this week (the held sheet's list).
        let parents: [UUID: [MessageEntry]]
    }

    /// The listed students' week: their books, checks, marks, the batches' sessions, the school's items and the log,
    /// read together; a failed read of the record or the log fails the card.
    func read(days: [UUID: Day], at moment: Date) async throws -> WeekRead {
        let ids = Array(days.keys)
        let centre = workspace.centre.id
        let weeks = days.mapValues { NoteDay.week(ending: $0, calendar: calendar) }
        let today = Day(moment, calendar: calendar)
        let thisMonday = today.adding(days: 1 - today.weekday(in: calendar).rawValue, calendar: calendar)
        let first = min(weeks.values.map(\.lowerBound).min() ?? thisMonday, thisMonday)
        let since = first.date(in: calendar)
        async let entriesRead = messages.entries(centre: centre, since: since)
        let students = ids.compactMap { register.student($0) }
        let records = try await NoteRecordReader(
            textbooks: textbooks, record: record, attendance: attendance, schoolItems: schoolItems
        ).read(students, centre: centre, from: first, to: today, calendar: calendar)
        let entries = try await entriesRead
        var rows: [NoteRowModel] = []
        var parents: [UUID: [MessageEntry]] = [:]
        for id in ids {
            guard let student = register.student(id), let noteDay = days[id], let week = weeks[id] else { continue }
            let theirs = entries.filter { register.sameParent($0.studentID, student) }.map(\.entry)
            parents[id] = theirs
                .filter {
                    MessageCadence.suggestedKinds.contains($0.kind) && $0.openedAt >= thisMonday.date(in: calendar)
                }
            let state = state(student, entries: entries, parent: theirs, week: week, at: moment)
            guard let record = records[id] else { continue }
            rows.append(NoteRowModel(
                id: id, name: student.name, initials: student.initials,
                line: line(record, state: state, week: week), state: state, noteDay: noteDay
            ))
        }
        return WeekRead(rows: rows, parents: parents)
    }

    /// Sent once the note or can-now-do was opened in WhatsApp since the week's Monday (the day after the note day, or
    /// after the note day moved, included); else the cadence's decision.
    func state(
        _ student: Student, entries: [StudentMessage], parent: [MessageEntry], week: ClosedRange<Day>, at moment: Date
    ) -> NoteRowModel.State {
        let monday = week.lowerBound.date(in: calendar)
        let sent = entries.contains {
            $0.studentID == student.id && [.note, .canDo].contains($0.entry.kind) && $0.entry.channel == .whatsAppLink
                && $0.entry.openedAt >= monday
        }
        if sent {
            return .sent
        }
        if case let .held(reason) = MessageCadence.decision(
            for: student, parentEntries: parent, now: moment, calendar: calendar
        ) {
            return .held(reason)
        }
        return .read
    }

    /// The language, then the topic and the lead fact; the reason for a held row.
    func line(_ record: NoteRecord, state: NoteRowModel.State, week: ClosedRange<Day>) -> String {
        let language = record.student.messageLanguage.title
        if case let .held(reason) = state {
            return "\(language) · \(MessageCadence.heldWords(reason))"
        }
        if CanDoWeek.isLadderNote(record.student, chapters: record.chapters) {
            let facts = CanDoWeek.facts(
                chapters: record.chapters,
                skills: record.skills,
                week: week,
                calendar: calendar
            )
            let can = facts.canDo.first.map { "Can now \(NoteWeek.lowered($0))" }
            return [language, can].compactMap(\.self).joined(separator: " · ")
        }
        let facts = NoteWeek.facts(record, week: week, calendar: calendar)
        let absent = record.sessions.filter {
            week.contains($0.date) && $0.marks[record.student.id] == .absent
        }.map(\.date).sorted()
        let topic = NoteWeek.topic(facts, chapters: record.chapters, skills: record.skills)
        let lead = facts.lead(status: record.student.trackStatus, absentDays: absent)
        return [language, topic, lead.isEmpty ? nil : lead].compactMap(\.self).joined(separator: " · ")
    }
}
