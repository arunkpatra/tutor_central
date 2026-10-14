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
        } else if await setAside() {
            return
        } else {
            await ask(student: student)
        }
    }

    /// The week's note the check set aside (D110): the card instead of asking again, which would pay to be refused
    /// again; true when it is so.
    private func setAside() async -> Bool {
        guard await context.online() else { return false }
        let since = week.lowerBound.date(in: context.calendar)
        let aside = try? await context.plans.setAsideNotes(
            centre: context.workspace.centre.id, students: [studentID], since: since
        )
        guard let draft = aside?[studentID] else { return false }
        setAsideDraft = draft
        // What it says stays under the card (P21-Note-SetAside): the week's facts from the record.
        if let student, let record = try? await context.reader.read(
            [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
            calendar: context.calendar
        )[student.id] {
            prepareFacts(record)
        }
        stage = .setAside
        return true
    }

    /// Write it myself (P21-Note-SetAside): the empty well for the tutor's own note, sent as any note.
    public func writeMyself() {
        guard stage == .setAside else { return }
        writingOwn = true
        message = ""
        english = nil
        stage = .ready
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

    /// A fresh draft, a new call though the facts are the same; the shown one stays kept (`regenerated_from`). With
    /// Write again's reason (P21-Note-Again, D107) the reason goes to the writer and is kept as feedback on the note
    /// shown, which stays on screen until the new one arrives.
    public func writeAgain(_ reason: NoteReason? = nil) async {
        guard let student, rewriting == nil else { return }
        if let reason, let generation = content?.generationID ?? kept?.generationID ?? setAsideDraft {
            await ArtefactFeedback.keep(
                .again(generation, reason: reason.words),
                recorder: feedback,
                centre: context.workspace.centre.id
            )
        }
        let shown = stage == .ready && kept != nil
        rewriting = shown ? reason : nil
        defer { rewriting = nil }
        await IdempotencyKey.another {
            await make(student: student, from: kept?.id, reason: reason?.words, keepShown: shown)
        }
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
        await keepSentFeedback()
        effects.copy(body)
        sent = true
        effects.open(AbsenceMessage.whatsAppURL(phone: phone, text: body))
        return true
    }

    var kind: MessageKind {
        isLadder ? .canDo : .note
    }

    /// What the tutor sent kept as feedback (D107): their own note in a set-aside one's place, or the draft they
    /// edited; an unchanged draft keeps nothing.
    private func keepSentFeedback() async {
        let sent = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let centre = context.workspace.centre.id
        if writingOwn, let draft = setAsideDraft {
            await ArtefactFeedback.keep(.replace(draft, with: .text(sent)), recorder: feedback, centre: centre)
            return
        }
        guard let generation = content?.generationID ?? kept?.generationID,
              let draft = content?.message.trimmingCharacters(in: .whitespacesAndNewlines),
              draft != sent else { return }
        await ArtefactFeedback.keep(.edit(generation, sent: sent), recorder: feedback, centre: centre)
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
            if await setAside() {
                return
            }
        }
        canRetry = true
        stage = .failed(APIFailure.timedOut.message)
    }

    /// Written here, at a tap that asks for it (Write again, the tutor's own words); `reason` is Write again's. With
    /// `keepShown` the note on screen stays until the new one arrives, and a failure keeps it and says so.
    private func make(student: Student, from previous: UUID?, reason: String? = nil, keepShown: Bool = false) async {
        guard let record = await keepShown ? prepareKeeping(student) : prepare(student) else { return }
        if !keepShown {
            stage = .writing
        }
        canRetry = false
        let words = isLadder ? nil : tutorSays ?? content?.tutorSays
        do {
            let artefact = try await context.writer.write(
                student, record: record, week: week, saying: words, asking: reason, replacing: previous
            )
            keepCopy(artefact)
            writingOwn = false
            setAsideDraft = nil
            show(artefact)
        } catch let failure as APIFailure {
            canRetry = !keepShown
            if keepShown {
                alert = Self.againFailed
            } else {
                stage = .failed(failure.message)
            }
        } catch {
            canRetry = !keepShown
            if keepShown {
                alert = Self.againFailed
            } else {
                stage = .failed("That didn't go through. Check your connection and try again.")
            }
        }
    }

    static let againFailed = "Couldn't write it again. The note you have is still here."

    /// The week's record for a note written over the one shown: offline or unread, the shown note stays and the alert
    /// says why.
    private func prepareKeeping(_ student: Student) async -> NoteRecord? {
        guard await context.online() else {
            alert = OfflineRefusal.words(for: .weeklyNote)
            return nil
        }
        let records = try? await context.reader.read(
            [student], centre: context.workspace.centre.id, from: week.lowerBound, to: noteDay,
            calendar: context.calendar
        )
        guard let record = records?[student.id] else {
            alert = Self.againFailed
            return nil
        }
        return record
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
