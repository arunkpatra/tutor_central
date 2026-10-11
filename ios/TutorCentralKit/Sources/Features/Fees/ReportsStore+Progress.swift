import Data
import Domain
import Foundation

/// Progress (P10-Reports-Progress, -Term; decisions 15 to 18): each active student's skills made secure, checks right
/// and absences over the month or the school's term, Lowest first, with the hero over the rows.
public extension ReportsStore {
    /// The month, or the term, Progress shows.
    var progressSpan: ProgressSpan {
        span == .term ? .term(term) : .month(month)
    }

    /// The header's words: the month, or on Progress by term "Term 1 · June to September".
    var spanTitle: String {
        segment == .progress ? progressSpan.title : monthTitle
    }

    /// The active students' rows, sorted; from this iPhone's copy while the network is away. An archived student is
    /// neither listed nor summed.
    var progressRows: [ProgressRow] {
        let active = register.activeStudents
        let rows: [ProgressRow] = if let progressCopy {
            progressCopy.filter { row in active.contains { $0.id == row.id } }
        } else {
            active.compactMap { student in
                progressInputs[student.id].map { ProgressRules.row($0, className: progressClass(student)) }
            }
        }
        return ProgressRules.sorted(rows, by: sort)
    }

    var progressHero: ProgressHero? {
        guard loaded else { return nil }
        return ProgressRules.hero(progressRows, span: progressSpan, now: Day(now(), calendar: calendar))
    }
}

extension ReportsStore {
    /// The calendar most of the active students' boards use, until the tutor steps the term.
    func followCentreCalendar() {
        guard !termMoved else { return }
        let calendarNow = Term.calendar(for: register.activeStudents.map(\.board))
        if calendarNow != term.calendar {
            term = Term.containing(Day(now(), calendar: calendar), calendar: calendarNow)
        }
    }

    func loadProgress(_ generation: Int) async {
        guard let progressReader else { return }
        let span = progressSpan
        let key = span.fileStem
        if progressShown != key {
            // A span not on screen yet: its copy at once while the network answers (hand run 14), else no rows.
            let copy = cache?.progress(key).load()
            (progressInputs, progressCopy, progressShown) = ([:], copy?.value, key)
            if let copy {
                (savedAt, loaded) = (copy.savedAt, true)
            }
        }
        do {
            let read = try await progressReader.read(
                register.activeStudents, span: span, centre: workspace.centre.id, calendar: calendar
            )
            guard generation == loadGeneration else { return }
            progressInputs = read
            progressCopy = nil
            (error, savedAt, offlineRead, loaded) = (nil, now(), false, true)
            cache?.progress(key).keep(progressRows, at: now())
        } catch {
            guard generation == loadGeneration else { return }
            if let copy = cache?.progress(key).load() {
                progressCopy = copy.value
                (self.error, savedAt, offlineRead, loaded) = (nil, copy.savedAt, TransportError.isOffline(error), true)
            } else {
                progressInputs = [:]
                progressCopy = nil
                (savedAt, offlineRead) = (nil, TransportError.isOffline(error))
                self.error = "Couldn't load the report. Check your connection and try again."
            }
        }
    }

    /// The row's class: the batch, else the class level.
    private func progressClass(_ student: Student) -> String {
        let batch = className(student)
        return batch.isEmpty ? student.classLevel?.title ?? "" : batch
    }
}
