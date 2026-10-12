import Data
import Domain
import Foundation

/// Opening a class and day: the month's copy at once, then the read (D76, U10, U27).
public extension AttendanceStore {
    /// A class and day (the menu, the date picker, Mark attendance on Today, the link): the month's copy on this
    /// iPhone shown at once (U27), then the month read (a spinner by the date meanwhile, U10); the saved session found
    /// and the draft made from it, unless the tutor has already changed it. `showingCopy` false (a reload) keeps what
    /// is shown until the read answers.
    func open(classID: UUID?, date: Day, showingCopy: Bool = true) async {
        openGeneration += 1
        let generation = openGeneration
        await register.loadIfNeeded()
        guard loadedMonth != date.period else {
            guard generation == openGeneration else { return }
            showDay(classID: classID, date: date)
            return
        }
        loading = true
        defer { loading = false }
        let centre = workspace.centre.id
        let (attendance, messages) = (attendance, messages)
        let outcome = await CopyFirst(cache: cache?(date.period), now: now)
            .load(showingCopy: showingCopy) { snapshot, at in
                guard generation == openGeneration else { return }
                (sessions, told) = (snapshot.sessions, snapshot.told)
                savedAt = at
                showDay(classID: classID, date: date)
            } read: {
                async let read = attendance.sessions(centre: centre, month: date.period)
                async let logs = messages.absences(centre: centre, month: date.period)
                let (month, monthLogs) = try await (read, logs)
                return AttendanceSnapshot(sessions: month, told: monthLogs)
            }
        guard generation == openGeneration else { return }
        guard let failure = outcome.failure else {
            loadedMonth = date.period
            offlineRead = false
            error = nil
            return
        }
        if TransportError.isCancelled(failure) {
            // The tab went away mid-read: nothing failed; the next visit opens again.
            if !opened {
                openGeneration = 0
            }
            return
        }
        offlineRead = TransportError.isOffline(failure)
        if case .nothing = outcome {
            error = "Couldn't load attendance. Check your connection and try again."
        } else {
            // The copy stays on screen; offline its line says so, any other failure says it in its place.
            error = offlineRead ? nil : "Couldn't load attendance. Check your connection and try again."
        }
        if !opened {
            showDay(classID: classID, date: date)
        }
    }

    /// The day's saved session found in the month shown and the draft made from it; a draft the tutor changed since the
    /// last one shown stays (a read answering after a toggle never undoes it).
    internal func showDay(classID: UUID?, date: Day) {
        let found = sessions.first { $0.date == date && $0.classID == classID }
        let members = AttendanceStore.members(of: classID, in: register)
        let sameDay = opened && draft.date == date && draft.classID == classID
        if sameDay, draft.isChanged(from: saved, members: members) {
            saved = found
            return
        }
        saved = found
        draft = AttendanceDraft(date: date, classID: classID, members: members, saved: found)
        phase = found.map { .reopened(savedAt: $0.savedAt) } ?? .fresh
        opened = true
    }
}
