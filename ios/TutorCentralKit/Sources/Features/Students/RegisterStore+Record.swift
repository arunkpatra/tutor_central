import Data
import Domain
import Foundation

/// What a saved student brings with them (Phase 11): the books of their school and class (plan decision 12), the ladder
/// for LKG to class 3, and the school's board when the school had none (plan decision 14). Each is best effort: the
/// student is saved; a step that fails is done again on the next save.
public extension RegisterStore {
    /// The tutor's last choice of a parent's message language: a new student starts with it (P10-NewStudent-End).
    var lastLanguage: MessageLanguage {
        get {
            languageDefaults?.string(forKey: Self.languageKey)
                .flatMap(MessageLanguage.init(rawValue:)) ?? languageInMemory
        }
        set {
            languageInMemory = newValue
            languageDefaults?.set(newValue.rawValue, forKey: Self.languageKey)
        }
    }

    /// The student form at its V2 fields: the batches, the schools and their counts, the last language.
    func form(_ mode: StudentFormStore.Mode) -> StudentFormStore {
        let form = StudentFormStore(
            mode: mode, classes: activeClasses, schools: schools, schoolCounts: schoolCounts, today: today,
            defaultLanguage: lastLanguage
        )
        form.memberCounts = Dictionary(grouping: activeStudents.compactMap(\.classID)) { $0 }.mapValues(\.count)
        return form
    }

    /// How many active students each school has (the school sheet's lines).
    var schoolCounts: [UUID: Int] {
        Dictionary(grouping: activeStudents.compactMap(\.schoolID)) { $0 }.mapValues(\.count)
    }
}

extension RegisterStore {
    static let languageKey = "lastMessageLanguage"

    func recordSaved(_ student: Student, before: Student?) async {
        let centre = workspace.centre.id
        lastLanguage = student.messageLanguage
        if let textbooksRepository, student.schoolID != nil, student.classLevel != nil,
           before == nil || before?.schoolID != student.schoolID || before?.classLevel != student.classLevel {
            _ = try? await textbooksRepository.copyAll(to: student.id, centre: centre)
        }
        if let textbooksRepository, student.classLevel?.usesLadder == true, before?.classLevel?.usesLadder != true {
            try? await textbooksRepository.ensureLadder(student: student.id, centre: centre)
        }
        if let schoolsRepository, let board = student.board, let id = student.schoolID,
           let index = schools.firstIndex(where: { $0.id == id }), schools[index].board == nil {
            if await (try? schoolsRepository.setBoard(id: id, board)) != nil {
                schools[index].board = board
            }
        }
    }

    /// Add a school from the school sheet's last row; nil (and the alert) when it does not save.
    public func addSchool(name: String) async -> School? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let schoolsRepository, !trimmed.isEmpty else { return nil }
        do {
            let made = try await schoolsRepository.create(name: trimmed, board: nil, centre: workspace.centre.id)
            schools.append(made)
            schools.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            return made
        } catch {
            let text = "Couldn't add \(trimmed). Check your connection and try again."
            failed(text, .addStudent, error: error) { [weak self] in _ = await self?.addSchool(name: trimmed) }
            return nil
        }
    }
}
