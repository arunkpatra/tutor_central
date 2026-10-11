import Data
import Domain
import Foundation

/// Phase 14's fixtures (plan/phase-14-plan.md decision 22): the note day on Sunday 11 October 18:30 over the Evening
/// batch and Class 10 Maths. Dev's parent writes in Hindi and agreed, Nikhil's and Sahil's in Kannada, Hemanth's in
/// Hindi, Meher's and Akshita's in English, all agreed; Riya's parent (Hindi) has not; the other students have no
/// number. Dev and Meher were sent this evening; Dev absent Monday and Wednesday, Nikhil Wednesday.
extension Fixtures {
    static let noteDayStates: Set<LaunchState> = [
        .todayNoteDay, .todayNoteHeld, .todayNoteDayChange, .note, .noteSend, .noteCanDo, .noteWriting,
        .studentMessages,
    ]

    static var noteDayClock: Date {
        india(day: 11, hour: 18, minute: 30)
    }

    static let noteDayListed = [
        FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil,
        FakeStudentsRepository.riya, FakeStudentsRepository.sahil, FakeStudentsRepository.hemanth,
        FakeStudentsRepository.akshita,
    ]

    /// The parents' languages and consent the note day reads; the students not listed lose their number.
    static func withParents(_ students: [Student], for state: LaunchState) -> [Student] {
        let languages: [UUID: MessageLanguage] = [
            FakeStudentsRepository.dev: .hindi, FakeStudentsRepository.nikhil: .kannada,
            FakeStudentsRepository.riya: .hindi, FakeStudentsRepository.sahil: .kannada,
            FakeStudentsRepository.hemanth: .hindi,
        ]
        return students.map { student in
            var changed = student
            if noteDayStates.contains(state) {
                changed.messageLanguage = languages[student.id] ?? .english
            }
            if student.id != FakeStudentsRepository.riya, let phone = student.parentPhone {
                changed.consent = ConsentRecord(at: india(day: 1, hour: 17, minute: 0), phone: phone, how: .inPerson)
            }
            if noteDayStates.contains(state), !noteDayListed.contains(student.id) {
                changed.parentPhone = nil
            }
            return changed
        }
    }

    /// The week's log: Dev's and Meher's notes opened at 18:20; for the held state Dev's three this week instead.
    static func noteDayEntries(for state: LaunchState) -> [UUID: [MessageEntry]] {
        let at = { (day: Int, hour: Int) in india(day: day, hour: hour, minute: 20) }
        let meher = [MessageEntry(id: UUID(), kind: .note, openedAt: at(11, 18), language: .english)]
        let devNote = MessageEntry(id: UUID(), kind: .note, openedAt: at(11, 18), language: .hindi)
        if state == .studentMessages {
            return [FakeStudentsRepository.dev: devLog]
        }
        guard state == .todayNoteHeld else {
            return [
                FakeStudentsRepository.dev: [devNote],
                FakeStudentsRepository.meher: meher,
            ]
        }
        let dev = [(MessageKind.testTomorrow, 6), (.testTomorrow, 7), (.notOnTrack, 9)].map {
            MessageEntry(id: UUID(), kind: $0.0, openedAt: at($0.1, 18), language: .hindi)
        }
        return [FakeStudentsRepository.dev: dev, FakeStudentsRepository.meher: meher]
    }

    /// The Evening batch's three classes this week: Dev absent Monday and Wednesday, Nikhil Wednesday.
    static var noteDaySessions: [AttendanceSession] {
        let members = FakeStudentsRepository.eveningSeed.filter { $0.classID == FakeClassesRepository.evening.id }
        return [5, 7, 9].map { day in
            var marks = Dictionary(uniqueKeysWithValues: members.map { ($0.id, AttendanceStatus.present) })
            if day != 9 {
                marks[FakeStudentsRepository.dev] = .absent
            }
            if day == 7 {
                marks[FakeStudentsRepository.nikhil] = .absent
            }
            let saved = india(day: day, hour: 18, minute: 30)
            return AttendanceSession(
                id: UUID(), classID: FakeClassesRepository.evening.id, date: Day(year: 2026, month: 10, day: day)!,
                savedAt: saved, marks: marks, closedAt: saved
            )
        }
    }

    /// Meher's four checks on Friday, all right; Nikhil's three, two right.
    static var noteDayChecks: [CheckRecord] {
        let friday = india(day: 9, hour: 18, minute: 0)
        let meher = (0 ..< 4).map { _ in (FakeStudentsRepository.meher, true) }
        let nikhil = [true, true, false].map { (FakeStudentsRepository.nikhil, $0) }
        return (meher + nikhil).enumerated().map { index, pair in
            CheckRecord(
                id: UUID(), studentID: pair.0, skillID: UUID(), sessionID: nil, question: "Q\(index)", correct: pair.1,
                at: friday, isPlacement: false
            )
        }
    }

    /// The Evening batch's books, with Sahil's reading moved up to Sentences on Thursday 8 October (P10-CanNowDo).
    @MainActor static func noteDayTextbooks() -> FakeTextbooksRepository {
        let books = FakeTextbooksRepository.evening()
        let sahil = FakeStudentsRepository.sahil
        let reading = books.chaptersByStudent[sahil]?.first { $0.ladder == .reading }?.id
        books.skillsByStudent[sahil] = books.skillsByStudent[sahil]?.map { skill in
            guard skill.chapterID == reading, skill.name == "Sentences" else { return skill }
            var moved = skill
            moved.state = .secure
            moved.stateAt = india(day: 8, hour: 17, minute: 30)
            return moved
        }
        return books
    }

    /// Dev's sent log (P10-Student-Messages): last Sunday's note opened on Monday, Test tomorrow on Wednesday, not on
    /// track
    /// on Friday; September's two notes. With the fee reminder of the seed that is three suggestions this week, so this
    /// Sunday's note is held.
    static var devLog: [MessageEntry] {
        let entry = { (kind: MessageKind, month: Int, day: Int, hour: Int) in
            MessageEntry(
                id: UUID(), kind: kind, openedAt: DayHeading.india.date(from: DateComponents(
                    year: 2026, month: month, day: day, hour: hour, minute: 10
                )) ?? now, language: .hindi
            )
        }
        return [
            entry(.note, 10, 5, 8), entry(.testTomorrow, 10, 7, 18), entry(.notOnTrack, 10, 9, 18),
            entry(.note, 9, 28, 8), entry(.note, 9, 20, 19),
        ]
    }

    /// Dev's kept notes: this Sunday's (held) and the three before it.
    static var devNotes: [Artefact] {
        [(9, 20, 9, 14), (9, 27, 9, 21), (10, 4, 9, 28), (10, 11, 10, 5)].map { month, day, mondayMonth, monday in
            let made = DayHeading.india.date(from: DateComponents(
                year: 2026, month: month, day: day, hour: 18, minute: 30
            )) ?? now
            let content = NoteContent(
                message: AISamplesNote.hindi, english: nil, language: .hindi,
                weekMonday: Day(year: 2026, month: mondayMonth, day: monday) ?? Day(now, calendar: DayHeading.india),
                facts: [], generationID: nil
            )
            return Artefact(
                id: UUID(), kind: .note, source: .made, title: "Dev's week", content: .note(content), photoPath: nil,
                studentID: FakeStudentsRepository.dev, planID: nil, regeneratedFrom: nil, madeAt: made
            )
        }
    }
}

/// The note's words in the fixtures' kept notes.
enum AISamplesNote {
    static let hindi = "नमस्ते रमेश जी, इस हफ़्ते देव ने रासायनिक समीकरण संतुलित करना सीखा। धन्यवाद।"
}
