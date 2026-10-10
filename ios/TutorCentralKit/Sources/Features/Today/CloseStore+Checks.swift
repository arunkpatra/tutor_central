import Data
import Domain
import Foundation

/// The checks of the close: three skills from the spaced queue asked in one call per subject, or the placement for a
/// student with nothing taught yet, made for every student at once.
extension CloseStore {
    /// The words in place when the checks need the network (plan Task 22): attendance and homework still close.
    nonisolated static let offlineWords = "You're offline. The checks need a connection; mark attendance and "
        + "homework, and Done still closes."
    /// While the checks are made (P12-Close-Cards, U38).
    nonisolated static let makingWords = "Making the three questions. A second or two."

    /// A student with no book (P12-Close-Cards, U37).
    nonisolated static func noBookWords(firstName: String) -> String {
        "No book yet, so no checks. Add one from \(firstName)'s page."
    }

    func makeChecks(_ indices: [Int]) async {
        let ids = indices.compactMap { students.indices.contains($0) ? students[$0].id : nil }
        await withTaskGroup(of: (UUID, CloseChecks).self) { group in
            for id in ids {
                group.addTask { await (id, self.checks(for: id)) }
            }
            for await (id, checks) in group {
                if let index = students.firstIndex(where: { $0.id == id }) {
                    students[index].checks = checks
                }
            }
        }
    }

    /// Try again for one student whose checks could not be made.
    public func retryChecks(for index: Int) async {
        guard students.indices.contains(index) else { return }
        students[index].checks = .loading
        let id = students[index].id
        if bookFailures[id] != nil {
            await keep(readBook(id))
        }
        await makeChecks([index])
    }

    private func checks(for id: UUID) async -> CloseChecks {
        if let failure = bookFailures[id] {
            return .failed(TransportError.isOffline(failure) ? Self.offlineWords
                : "Couldn't load the checks. Check your connection and try again.")
        }
        let chapters = chapters[id] ?? [], skills = skills[id] ?? []
        guard !chapters.isEmpty, let level = register.student(id)?.classLevel else { return .none }
        let picked = SpacedQueue.pick(skills: skills, chapters: chapters, now: now(), calendar: calendar)
        guard !picked.isEmpty else {
            return await placement(level: level, chapters: chapters, skills: skills)
        }
        let subjects = Dictionary(chapters.map { ($0.id, $0.subject) }) { first, _ in first }
        var order: [String] = []
        for skill in picked {
            let subject = subjects[skill.chapterID] ?? ""
            if !order.contains(subject) {
                order.append(subject)
            }
        }
        var lines: [CheckLine] = []
        for subject in order {
            let asked = picked.filter { subjects[$0.chapterID] == subject }
            do {
                let questions = try await ai.makeChecks(
                    classLevel: level, subject: subject, skills: asked.map(\.name), centre: workspace.centre.id
                )
                lines += zip(asked, questions).map { skill, made in
                    CheckLine(
                        skillID: skill.id, skill: skill.name, question: made.question, answer: made.answer, tap: nil,
                        recorded: nil, isPlacement: false
                    )
                }
            } catch {
                return .failed(Self.words(error))
            }
        }
        let rank = Dictionary(uniqueKeysWithValues: picked.enumerated().map { ($1.id, $0) })
        return .rows(lines.sorted { rank[$0.skillID, default: 0] < rank[$1.skillID, default: 0] })
    }

    private func placement(level: ClassLevel, chapters: [Chapter], skills: [Skill]) async -> CloseChecks {
        var subjects: [PlacementSubject] = []
        for group in Placement.groups(chapters: chapters, skills: skills) {
            do {
                let questions = try await ai.makePlacement(
                    classLevel: level, subject: group.title, chapters: group.items.map(\.name),
                    centre: workspace.centre.id
                )
                subjects.append(PlacementSubject(
                    title: group.title, rows: Placement.rows(
                        group,
                        questions: questions.map { ($0.question, $0.answer) }
                    ),
                    failure: nil
                ))
            } catch {
                if error == .offline {
                    return .failed(Self.offlineWords)
                }
                subjects.append(PlacementSubject(title: group.title, rows: [], failure: error.message))
            }
        }
        if let failure = subjects.first?.failure, subjects.allSatisfy({ $0.failure != nil }) {
            return .failed(failure)
        }
        return subjects.isEmpty ? .none : .placement(subjects)
    }

    private static func words(_ error: APIFailure) -> String {
        error == .offline ? offlineWords : error.message
    }
}
