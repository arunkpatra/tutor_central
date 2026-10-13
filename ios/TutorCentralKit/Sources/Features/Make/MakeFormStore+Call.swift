import Data
import Domain
import Foundation

/// Make: the note opens Phase 14's note; a mock already made opens; else the call, which is the shell's store's
/// (decision 13).
public extension MakeFormStore {
    func make() async -> MakeOutcome {
        alert = nil
        if kind == .noteToParent {
            return note()
        }
        guard canMake else { return .refused }
        guard await context.online() else {
            alert = OfflineRefusal.words(for: .make)
            return .refused
        }
        if case let .item(item)? = exam, kind == .mock,
           let existing = await (try? context.plans.mock(for: item.id, centre: context.workspace.centre.id)) ?? nil {
            return .opensExisting(existing.id)
        }
        guard let job = job() else { return .refused }
        guard let task = make.run(kind, job: job) else {
            alert = "One at a time: the last one is still being made."
            return .refused
        }
        remember()
        let made = await task.value
        if made == nil, let paused = make.paused, paused.kind == kind {
            make.paused = nil
            alert = paused.words
            return .refused
        }
        return made.map(MakeOutcome.made) ?? .failed
    }

    /// The note's student with consent: the note day of their batch, with the tutor's words; without consent, refused
    /// in the note screen's words before any call (D62).
    private func note() -> MakeOutcome {
        guard let student = studentID.flatMap(context.register.student) else { return .refused }
        guard student.consent != nil else {
            alert = NoteConsent.waiting(student)
            return .refused
        }
        let noteDay = (context.register.classroom(student.classID)?.noteDay ?? .default)
            .noteDay(for: context.now(), calendar: context.calendar)
        let words = tutorSays.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = words
            .isEmpty ? nil : String(String.UnicodeScalarView(words.unicodeScalars.prefix(MakeRules.tutorSaysLimit)))
        remember()
        return .opensNote(student.id, noteDay, tutorSays: kept)
    }

    /// The call and the keep for the kind, from the form as it stands now.
    private func job() -> (@MainActor () async throws -> Artefact)? {
        guard let level else { return nil }
        let topic = Topic(
            level: level, subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
            skill: skill.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        switch kind {
        case .sheet: return sheetJob(topic)
        case .workedExample: return exampleJob(topic)
        case .figure: return figureJob(topic)
        case .brief: return briefJob(level: level, subject: topic.subject)
        case .mock: return mockJob(level: level)
        case .noteToParent, .paper, .homework, .worksheet: return nil
        }
    }

    /// What the group kinds are made from: the level, the subject and one skill.
    private struct Topic {
        let level: ClassLevel
        let subject: String
        let skill: String
    }

    private var targetStudent: UUID? {
        if case let .student(id)? = target {
            id
        } else {
            nil
        }
    }

    private func words(_ topic: Topic) -> MakeFor? {
        target.map { MakeRules.forWords($0, roster: roster, subject: topic.subject, skill: topic.skill) }
    }

    /// Keeps an artefact as Make's.
    private func keeper(student: UUID?, exam: UUID?) -> @MainActor (NewArtefact) async throws -> Artefact {
        let plans = context.plans
        let centre = context.workspace.centre.id
        return { try await plans.keepMade($0, student: student, exam: exam, centre: centre) }
    }

    private func sheetJob(_ topic: Topic) -> (@MainActor () async throws -> Artefact)? {
        guard let made = words(topic)?.keepingKey(keyAtEnd) else { return nil }
        let (ai, centre, keep) = (context.ai, context.workspace.centre.id, keeper(student: targetStudent, exam: nil))
        let request = SheetRequest(
            classLevel: topic.level, subject: topic.subject, skills: [topic.skill], questions: length,
            forHomework: false, reason: levelReason
        )
        return {
            let sheet = try await ai.makeSheet(request, centre: centre)
            return try await keep(NewArtefact(
                kind: .sheet, source: .made, title: "\(topic.skill) · sheet", content: .sheet(sheet.content),
                photoPath: nil, generationID: sheet.generationID, regeneratedFrom: nil
            ).made(for: made))
        }
    }

    private func exampleJob(_ topic: Topic) -> (@MainActor () async throws -> Artefact)? {
        guard let made = words(topic) else { return nil }
        let (ai, centre, keep) = (context.ai, context.workspace.centre.id, keeper(student: targetStudent, exam: nil))
        return {
            let example = try await ai.makeWorkedExample(
                classLevel: topic.level, subject: topic.subject, skill: topic.skill, centre: centre
            )
            return try await keep(NewArtefact(
                kind: .workedExample, source: .made, title: topic.skill, content: .workedExample(example.example),
                photoPath: nil, generationID: example.generationID, regeneratedFrom: nil
            ).made(for: made))
        }
    }

    private func figureJob(_ topic: Topic) -> (@MainActor () async throws -> Artefact)? {
        guard let made = words(topic), let template else { return nil }
        let (ai, centre, keep) = (context.ai, context.workspace.centre.id, keeper(student: targetStudent, exam: nil))
        return {
            let figure = try await ai.makeFigure(
                template, classLevel: topic.level, subject: topic.subject, skill: topic.skill, centre: centre
            )
            guard figure.figure.figure.kind == template, figure.figure.figure.validate() == nil else {
                throw MakeRefusal()
            }
            return try await keep(NewArtefact(
                kind: .figure, source: .made, title: topic.skill, content: .figure(figure.figure), photoPath: nil,
                generationID: figure.generationID, regeneratedFrom: nil
            ).made(for: made))
        }
    }

    private func briefJob(level: ClassLevel, subject: String) -> @MainActor () async throws -> Artefact {
        let chapter = chapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let made = MakeRules.forWords(.classLevel(level), roster: roster, subject: subject, skill: chapter)
        let (ai, centre, keep) = (context.ai, context.workspace.centre.id, keeper(student: nil, exam: nil))
        return {
            let brief = try await ai.makeBrief(classLevel: level, subject: subject, chapter: chapter, centre: centre)
            return try await keep(NewArtefact(
                kind: .brief, source: .made, title: chapter, content: .brief(brief.brief), photoPath: nil,
                generationID: brief.generationID, regeneratedFrom: nil
            ).made(for: made))
        }
    }

    private func mockJob(level: ClassLevel) -> (@MainActor () async throws -> Artefact)? {
        guard let studentID, let exam else { return nil }
        let request = switch exam {
        case let .item(item):
            MockRequest(
                classLevel: level, subject: item.subject ?? "", title: item.title,
                portions: Self.portions(item.portions ?? item.title), pattern: .default(for: level),
                schoolItemID: item.id
            )
        case let .typed(subject, title, portions):
            MockRequest(
                classLevel: level, subject: subject, title: title, portions: Self.portions(portions),
                pattern: .default(for: level)
            )
        }
        let made = MakeRules.forWords(.student(studentID), roster: roster, subject: request.subject, skill: nil)
            .making(level: level, subject: request.subject, skills: request.portions)
        let (ai, centre) = (context.ai, context.workspace.centre.id)
        let keep = keeper(student: studentID, exam: request.schoolItemID)
        return {
            let mock = try await ai.makeMock(request, centre: centre)
            return try await keep(NewArtefact(
                kind: .mock, source: .made, title: "\(request.title) · mock", content: .mock(mock.content),
                photoPath: nil, generationID: mock.generationID, regeneratedFrom: nil
            ).made(for: made))
        }
    }

    /// The portions as the API takes them: the parts the tutor or the school separated, at most 30.
    static func portions(_ text: String) -> [String] {
        let parts = text.split(whereSeparator: { "·,;\n".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array((parts.isEmpty ? [text] : parts).prefix(30)).map { String($0.prefix(120)) }
    }
}
