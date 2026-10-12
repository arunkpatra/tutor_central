import Data
import Domain
import Foundation

extension NoteStore {
    /// The note kept this week: the copy on this iPhone at once (U47: a connection that hangs takes 20 s to give up),
    /// then the plans' (the newer when both), else asked of the server (the note day's job did not write it); the
    /// tutor's own words write a new one here.
    public func load() async {
        // A link or a launch state can open the note before the register is read.
        await context.register.loadIfNeeded()
        guard let student else {
            stage = .failed("This student is no longer here.")
            return
        }
        let copy = copiedNote()
        if let copy {
            show(copy)
        }
        let served = await servedNote()
        guard !Task.isCancelled else { return }
        if let found = served ?? copy, tutorSays != nil {
            show(found)
            await make(student: student, from: found.id)
            return
        }
        if let found = served ?? copy {
            if found.kind == .canDo, let record = try? await context.reader.read(
                [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
                calendar: context.calendar
            )[student.id] {
                // "Moved up" is drawn from the ladder; the kept note's own facts stand.
                prepareFacts(record)
            }
            show(found)
            return
        }
        if tutorSays != nil {
            await make(student: student, from: nil)
        } else {
            await ask(student: student)
        }
    }

    /// Try Again after a failure: the note asked of the server again, or the call made again.
    public func make() async {
        guard let student else { return }
        if kept == nil, tutorSays == nil {
            await ask(student: student)
        } else {
            await make(student: student, from: kept?.id)
        }
    }

    /// Reads while an asked note is written: every five seconds for two minutes.
    static let askedReads = 24

    /// A fresh draft, a new call though the facts are the same; the shown one stays kept (`regenerated_from`).
    public func writeAgain() async {
        guard let student else { return }
        await IdempotencyKey.another { await make(student: student, from: kept?.id) }
    }

    /// Copy: the signed note on the pasteboard, logged as copied when a connection allows; nothing is sent.
    public func copy() async {
        let body = signedBody
        effects.copy(body)
        guard await context.online() else { return }
        _ = try? await context.messages.logMessage(
            ParentMessage(studentID: studentID, kind: kind, language: language, body: body, channel: .copied),
            centre: context.workspace.centre.id
        )
    }

    /// The two-language sheet's Open WhatsApp: the kind, the language and the signed words logged, then copied and the
    /// link opened (D3). Nothing is logged over the limit or offline.
    public func send() async -> Bool {
        guard canSend, let phone = student?.parentPhone else { return false }
        guard await context.online() else {
            alert = OfflineRefusal.words(for: .sendNote)
            return false
        }
        let body = signedBody
        do {
            _ = try await context.messages.logMessage(
                ParentMessage(studentID: studentID, kind: kind, language: language, body: body, channel: .whatsAppLink),
                centre: context.workspace.centre.id
            )
        } catch {
            alert = "That didn't go through. Check your connection and try again."
            return false
        }
        effects.copy(body)
        sent = true
        effects.open(AbsenceMessage.whatsAppURL(phone: phone, text: body))
        return true
    }

    var kind: MessageKind {
        isLadder ? .canDo : .note
    }

    private func ofThisWeek(_ artefact: Artefact) -> Bool {
        guard artefact.studentID == studentID, case let .note(content) = artefact.content else { return false }
        return content.weekMonday == week.lowerBound
    }

    /// This week's note in the copy on this iPhone.
    private func copiedNote() -> Artefact? {
        context.notesCache?.read().sorted { $0.madeAt > $1.madeAt }.first(where: ofThisWeek)
    }

    /// This week's note in the plans; nil offline or when the read fails.
    private func servedNote() async -> Artefact? {
        guard await context.online() else { return nil }
        let since = week.lowerBound.date(in: context.calendar)
        let read = try? await context.plans.notes(
            centre: context.workspace.centre.id,
            students: [studentID],
            since: since
        )
        return read?.first(where: ofThisWeek)
    }

    private func show(_ artefact: Artefact) {
        guard case let .note(content) = artefact.content else { return }
        kept = artefact
        self.content = content
        isLadder = artefact.kind == .canDo
        message = content.message
        english = content.english
        facts = content.facts
        stage = .ready
    }

    /// The week's record read and its facts shown; nil with the failure shown when the note cannot be written now
    /// (no consent, offline, the record unread).
    private func prepare(_ student: Student) async -> NoteRecord? {
        let records = try? await context.reader.read(
            [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
            calendar: context.calendar
        )
        let record = records?[student.id]
        if let record {
            prepareFacts(record)
        }
        guard student.consent != nil else {
            stage = .failed(NoteConsent.waiting(student))
            return nil
        }
        guard await context.online() else {
            stage = .failed(OfflineRefusal.words(for: .weeklyNote))
            return nil
        }
        guard let record else {
            stage = .failed("Couldn't read this week's record. Check your connection and try again.")
            return nil
        }
        return record
    }

    /// The note the note day's job did not write, asked of the server (`request_note`): the writing card while the
    /// store
    /// reads again, every five seconds for up to two minutes; then the timed-out words with Try Again.
    private func ask(student: Student) async {
        guard await prepare(student) != nil else { return }
        stage = .writing
        canRetry = false
        do {
            _ = try await context.jobs.requestNote(
                centre: context.workspace.centre.id, student: student.id, week: week.lowerBound
            )
        } catch {
            canRetry = true
            stage = .failed("That didn't go through. Check your connection and try again.")
            return
        }
        // Read at once (a job already done answers the same note), then every five seconds.
        for read in 0 ..< Self.askedReads {
            if read > 0 {
                guard await (try? context.pause()) != nil, !Task.isCancelled else { return }
            }
            if let found = await servedNote() {
                keepCopy(found)
                show(found)
                return
            }
        }
        canRetry = true
        stage = .failed(APIFailure.timedOut.message)
    }

    /// Written here, at a tap that asks for it (Write again, the tutor's own words).
    private func make(student: Student, from previous: UUID?) async {
        guard let record = await prepare(student) else { return }
        stage = .writing
        canRetry = false
        let words = isLadder ? nil : tutorSays ?? content?.tutorSays
        do {
            let artefact = try await context.writer.write(
                student, record: record, week: week, saying: words, replacing: previous
            )
            keepCopy(artefact)
            show(artefact)
        } catch let failure as APIFailure {
            canRetry = true
            stage = .failed(failure.message)
        } catch {
            canRetry = true
            stage = .failed("That didn't go through. Check your connection and try again.")
        }
    }

    /// The facts the screen shows while the note is written, and "Moved up" for the ladder.
    private func prepareFacts(_ record: NoteRecord) {
        isLadder = CanDoWeek.isLadderNote(record.student, chapters: record.chapters)
        guard isLadder else {
            facts = NoteWeek.facts(record, week: week, calendar: context.calendar).rows
            ladder = nil
            return
        }
        let can = CanDoWeek.facts(
            chapters: record.chapters,
            skills: record.skills,
            week: week,
            calendar: context.calendar
        )
        facts = can.rows
        let area = can.movedUp.first?.area ?? .reading
        let step = can.movedUp.first.flatMap { area.steps.firstIndex(of: $0.step) }
            ?? ladderStep(area, record: record)
        ladder = LadderModel(
            heading: can.ladderHeading, area: area.title, steps: area.steps, current: step, line: can.movedUpLine
        )
    }

    /// The highest secure step of an area, the first when none is.
    private func ladderStep(_ area: Ladder.Area, record: NoteRecord) -> Int {
        guard let chapter = record.chapters.first(where: { $0.ladder == area }) else { return 0 }
        let states = record.skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
            .map(\.state)
        return max(0, (Ladder.currentStep(states) ?? states.count) - 1)
    }

    private func keepCopy(_ artefact: Artefact) {
        guard let cache = context.notesCache else { return }
        let since = week.lowerBound.date(in: context.calendar)
        let others = cache.read().filter { $0.id != artefact.id && $0.madeAt >= since.addingTimeInterval(-7 * 86400) }
        try? cache.keep([artefact] + others)
    }
}
