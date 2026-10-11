import Domain
import Foundation

extension MessagesStore {
    /// The log's rows: a kept weekly note (or can-now-do) dated by its making, with the send that opened it ("opened
    /// Mon", "copied Sun", "not opened yet"); every other message dated by its send. The held note is left to Held.
    func rows(entries: [MessageEntry], notes: [Artefact]) -> [(Date, Row)] {
        var used = Set<UUID>()
        var rows: [(Date, Row)] = []
        let byWeek = Dictionary(grouping: notes.compactMap { artefact -> (Day, Artefact)? in
            guard case let .note(content) = artefact.content else { return nil }
            return (content.weekMonday, artefact)
        }, by: \.0).compactMapValues { $0.map(\.1).max { $0.madeAt < $1.madeAt } }
        for (_, note) in byWeek {
            guard case let .note(content) = note.content else { continue }
            let made = Day(note.madeAt, calendar: calendar)
            if let held, held.noteDay == made {
                continue
            }
            let from = NoteDay.sendsFrom(made).date(in: calendar)
            let until = made.adding(days: 2, calendar: calendar).date(in: calendar)
            let sends = entries.filter {
                [.note, .canDo].contains($0.kind) && $0.openedAt >= from && $0.openedAt < until && !used.contains($0.id)
            }
            let send = sends.first { $0.channel == .whatsAppLink } ?? sends.first
            send.map { used.insert($0.id) }
            let state = send.map { entry in
                let day = Day(entry.openedAt, calendar: calendar).shortWeekday
                return "\(entry.channel == .copied ? "copied" : "opened") \(day)"
            } ?? "not opened yet"
            rows.append((note.madeAt, Row(
                id: note.id, symbol: Self.symbol(note.kind == .canDo ? .canDo : .note),
                title: note.kind == .canDo ? MessageKind.canDo.title : MessageKind.note.title,
                line: "\(made.shortWeekdayText) · \(content.language.title) · \(state)", opens: made
            )))
        }
        for entry in entries where !used.contains(entry.id) {
            let day = Day(entry.openedAt, calendar: calendar)
            let parts: [String] = if let language = entry.language {
                [
                    day.shortWeekdayText,
                    language.title,
                    "\(entry.channel == .copied ? "copied" : "opened") \(day.shortWeekday)",
                ]
            } else {
                // V1's messages are the English templates; their log keeps no language.
                [day.shortWeekdayText, MessageLanguage.english.title]
            }
            rows.append((entry.openedAt, Row(
                id: entry.id, symbol: Self.symbol(entry.kind), title: entry.kind.title,
                line: parts.joined(separator: " · "), opens: nil
            )))
        }
        return rows
    }

    /// By month, newest first.
    static func months(_ rows: [(Date, Row)], calendar: Calendar) -> [Month] {
        let sorted = rows.sorted { $0.0 > $1.0 }
        var months: [Month] = []
        for (date, row) in sorted {
            let title = Day(date, calendar: calendar).period.monthName
            if months.last?.title == title {
                months[months.count - 1] = Month(title: title, rows: months[months.count - 1].rows + [row])
            } else {
                months.append(Month(title: title, rows: [row]))
            }
        }
        return months
    }

    /// The note of the latest note day held: not opened in WhatsApp since that note day's window opened, and held by
    /// the cadence on the note day (three that week, or no consent). Nothing when the student has no number.
    func heldNote(_ student: Student, entries: [MessageEntry], parent: [MessageEntry]) -> Held? {
        let noteDay = (register.classroom(student.classID)?.effectiveNoteDay ?? .default)
        let day = noteDay.noteDay(for: now(), calendar: calendar)
        let from = NoteDay.sendsFrom(day).date(in: calendar)
        let sent = entries
            .contains { [.note, .canDo].contains($0.kind) && $0.channel == .whatsAppLink && $0.openedAt >= from }
        let moment = calendar.date(
            bySettingHour: noteDay.time.hour, minute: noteDay.time.minute, second: 0, of: day.date(in: calendar)
        ) ?? day.date(in: calendar)
        guard !sent, case let .held(reason) = MessageCadence.decision(
            for: student, parentEntries: parent.filter { $0.openedAt <= moment }, now: moment, calendar: calendar
        ) else { return nil }
        let why = switch reason {
        case .threeThisWeek:
            "\(student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) } ?? "The parent") had "
                + "three messages that week"
        case .consent: MessageCadence.heldWords(reason)
        }
        return Held(
            title: MessageKind.note.title, line: "Held since \(day.shortWeekdayText) · \(why)", noteDay: day,
            waitsForConsent: reason != .threeThisWeek
        )
    }

    static func symbol(_ kind: MessageKind) -> String {
        switch kind {
        case .notOnTrack: "exclamationmark.circle"
        case .testTomorrow: "doc.text"
        case .forwardAsk: "arrowshape.turn.up.forward"
        default: StudentDetailStore.symbol(kind)
        }
    }
}
