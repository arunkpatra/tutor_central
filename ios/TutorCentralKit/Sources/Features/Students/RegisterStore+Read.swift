import Data
import Domain
import Foundation

/// The register's reads: the copy at once, then the students and batches read together (D76).
public extension RegisterStore {
    /// The copy at once, then the register read (D76); a failed read keeps what is shown.
    func load() async {
        if !loaded {
            loading = true
        } else {
            refreshing = true
        }
        defer { loading = false; refreshing = false }
        await fetch(showingCopy: !loaded)
    }

    /// For a screen pushed over the list (a detail, a link) and Today: read only when nothing has been read or cached
    /// yet. A copy on this iPhone answers at once and the read runs on: offline it takes its timeout to fail, and
    /// Today's plans and note day wait for this (Phase 18's hand run 8).
    func loadIfNeeded() async {
        guard !loaded else { return }
        guard let copy = cache?.load() else {
            await load()
            return
        }
        show(copy, savedAt: copy.savedAt)
        Task { await refresh() }
    }

    func refresh() async {
        refreshing = true
        defer { refreshing = false }
        await fetch(showingCopy: false)
    }

    internal func fetch(showingCopy: Bool) async {
        let (students, classes, centre, period, cache) = (
            studentsRepository, classesRepository, workspace.centre.id, period, cache
        )
        let reader = CopyFirst<RegisterSnapshot>(
            copy: { cache?.load().map { CachedValue(value: $0, savedAt: $0.savedAt ?? .distantPast) } },
            keep: { snapshot, at in
                var kept = snapshot
                kept.savedAt = at
                try? cache?.save(kept)
            },
            now: now
        )
        let outcome = await reader.load(showingCopy: showingCopy) { snapshot, at in
            show(snapshot, savedAt: at == .distantPast ? nil : at)
            if loading {
                // The copy is on screen: what runs now is a refresh.
                (loading, refreshing) = (false, true)
            }
        } read: {
            async let read = students.students(centre: centre, period: period)
            async let classRead = classes.classes(centre: centre)
            return try await RegisterSnapshot(students: read, classes: classRead, period: period)
        }
        guard let failure = outcome.failure else {
            await readSchools()
            error = nil
            offlineRead = false
            return
        }
        // Its screen went away mid-read: nothing failed; the next visit reads again.
        if TransportError.isCancelled(failure) {
            return
        }
        offlineRead = TransportError.isOffline(failure)
        // A saved register offline: the line under the title says it.
        error = loaded && offlineRead ? nil : "Couldn't refresh. Check your connection and try again."
    }

    internal func show(_ snapshot: RegisterSnapshot, savedAt: Date?) {
        self.savedAt = savedAt
        classes = snapshot.classes
        students = snapshot.period == period ? snapshot.students : snapshot.students.map(Self.withoutFeeMark)
        loaded = true
    }

    /// The schools ride along with the register; a failed read keeps the ones shown (the form still saves without).
    internal func readSchools() async {
        guard let schoolsRepository else { return }
        if let read = try? await schoolsRepository.schools(centre: workspace.centre.id) {
            schools = read
        }
    }
}
