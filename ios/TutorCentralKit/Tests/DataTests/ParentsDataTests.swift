import Domain
import Foundation
import Testing
@testable import Data

/// Phase 14's rows and fakes: the log's channel and body, the note day and next step, the exam's window, the notes
/// kept.
struct ParentsRowTests {
    @Test func aRowReadsItsChannelAndBodyAndAnOlderRowDefaultsToWhatsApp() throws {
        let copied = """
        {"id":"\(UUID())","kind":"note","opened_at":"2026-10-11T13:00:00Z","language":"kn","channel":"copied",\
        "body":"ನಮಸ್ಕಾರ"}
        """
        let entry = try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(copied.utf8))
            .entry
        #expect(entry?.channel == .copied && entry?.body == "ನಮಸ್ಕಾರ" && entry?.kind == .note)
        let old = """
        {"id":"\(UUID())","kind":"reminder","opened_at":"2026-10-06T04:45:00Z","language":null}
        """
        let older = try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(old.utf8)).entry
        #expect(older?.channel == .whatsAppLink && older?.body == nil)
    }

    @Test func aNotOnTrackRowReadsAsItsKind() throws {
        let row = """
        {"id":"\(UUID())","kind":"not_on_track","opened_at":"2026-10-09T13:00:00Z","language":"hi",\
        "channel":"whatsapp_link","body":"…"}
        """
        let entry = try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(row.utf8)).entry
        #expect(entry?.kind == .notOnTrack)
    }

    @Test func aBatchReadsItsNoteDayAndNoneReadsNil() throws {
        let base = #""id":"\#(UUID())","name":"Evening batch","subject":null,"monthly_fee":null,"meeting_days":[1],"#
            + #""start_time":null,"end_time":null,"archived_at":null,"plan_groups":null,"plan_pattern":null"#
        let set = try SupabaseClassesRepository.decoder.decode(
            ClassroomRow.self, from: Data("{\(base),\"note_weekday\":6,\"note_time\":\"18:00:00\"}".utf8)
        ).classroom
        #expect(try set.noteDay == NoteDay(weekday: .saturday, time: #require(TimeOfDay(hour: 18, minute: 0))))
        let none = try SupabaseClassesRepository.decoder.decode(ClassroomRow.self, from: Data("{\(base)}".utf8))
        #expect(none.classroom.noteDay == nil)
        #expect(SupabaseClassesRepository.noteDayValues(nil) == ["note_weekday": .null, "note_time": .null])
        #expect(SupabaseClassesRepository.noteDayValues(NoteDay.default)
            == ["note_weekday": .integer(7), "note_time": .string("18:00")])
    }

    @Test func aStudentReadsItsNextStep() throws {
        let json = """
        {"id":"\(UUID())","name":"Dev Kumar","class_id":null,"monthly_fee":null,"parent_name":null,\
        "parent_phone":null,"date_of_birth":null,"gender":null,"notes":null,"archived_at":null,"next_step":"step_back"}
        """
        let student = try SupabaseStudentsRepository.decoder.decode(StudentRow.self, from: Data(json.utf8))
            .student(calendar: DayHeading.india)
        #expect(student.nextStep == .stepBack)
    }

    @Test func theWindowReadsAndWritesAndNilMeansFourteen() throws {
        let row = { (window: String) in
            Data("""
            {"id":"\(UUID())","kind":"exam","school_id":null,"student_id":"\(UUID())","class_level":null,\
            "title":"Unit test","subject":"Science","date":"2026-10-16","end_date":null,"portions":null,\
            "source_text":null,"photo_path":null,"source":"typed","received_at":"2026-10-07T09:34:00+00:00",\
            "confirmed_at":null,"window_days":\(window)}
            """.utf8)
        }
        var item = try #require(
            SupabaseSchoolItemsRepository.decoder.decode(SchoolItemRow.self, from: row("7")).item
        )
        #expect(item.windowDays == 7)
        #expect(try SupabaseSchoolItemsRepository.decoder.decode(SchoolItemRow.self, from: row("null")).item?
            .windowDays == nil)
        item.windowDays = 21
        let write = try #require(String(bytes: JSONEncoder().encode(SchoolItemWrite(item: item)), encoding: .utf8))
        #expect(write.contains("\"window_days\":21"))
        item.windowDays = nil
        let cleared = try #require(String(bytes: JSONEncoder().encode(SchoolItemWrite(item: item)), encoding: .utf8))
        #expect(cleared.contains("\"window_days\":null"))
    }

    @Test func aNoteIsKeptWithNoPlanForItsStudent() throws {
        let note = NewNote(
            studentID: FakeStudentsRepository.dev, kind: .note, title: "Dev's week",
            content: ParentsSamples.content, regeneratedFrom: nil
        )
        let params = try SupabasePlansRepository.keepParams(note.artefact, to: note.link, centre: UUID())
        #expect(params["p_plan"] == .null && params["p_student"] ==
            .string(FakeStudentsRepository.dev.uuidString.lowercased()))
        guard case let .object(row)? = params["p_artefact"], case let .object(content)? = row["content"] else {
            Issue.record("no content")
            return
        }
        #expect(row["kind"] == .string("note") && content["week_monday"] == .string("2026-10-05"))
    }
}

@MainActor struct FakeRepositoriesParentsTests {
    @Test func theFakeLogKeepsAMessageWithItsKindLanguageBodyAndChannel() async throws {
        let log = FakeMessageLogRepository()
        let dev = FakeStudentsRepository.dev
        for channel in [MessageChannel.whatsAppLink, .copied] {
            let message = ParentMessage(studentID: dev, kind: .note, language: .hindi, body: "नमस्ते", channel: channel)
            _ = try await log.logMessage(message, centre: UUID())
        }
        let entries = try await log.messages(centre: UUID(), student: dev)
        #expect(Set(entries.map(\.channel)) == [.copied, .whatsAppLink] && entries.allSatisfy { $0.body == "नमस्ते" })
        #expect(log.messageLogs.count == 2 && log.messageLogs.first?.kind == .note)
    }

    @Test func theFakePlansKeepAndFindTheWeeksNotes() async throws {
        let plans = FakePlansRepository()
        let dev = FakeStudentsRepository.dev
        let note = NewNote(
            studentID: dev, kind: .note, title: "Dev's week", content: ParentsSamples.content, regeneratedFrom: nil
        )
        let kept = try await plans.keepNote(note, centre: UUID())
        let since = try #require(Day(year: 2026, month: 10, day: 5)?.date(in: DayHeading.india))
        let found = try await plans.notes(centre: UUID(), students: [dev], since: since)
        #expect(found.map(\.id) == [kept.id] && found.first?.content == .note(ParentsSamples.content))
        #expect(found.first?.studentID == dev && found.first?.planID == nil)
        let again = try await plans.keepNote(
            NewNote(
                studentID: dev, kind: .note, title: "Dev's week", content: ParentsSamples.content,
                regeneratedFrom: kept.id
            ),
            centre: UUID()
        )
        #expect(again.regeneratedFrom == kept.id)
        #expect(try await plans.notes(centre: UUID(), students: [FakeStudentsRepository.riya], since: since).isEmpty)
    }

    @Test func theFakeClassesKeepTheNoteDayAndStudentsTheNextStep() async throws {
        let classes = FakeClassesRepository(classes: FakeClassesRepository.withEvening)
        let saturday = try NoteDay(weekday: .saturday, time: #require(TimeOfDay(hour: 18, minute: 0)))
        let changed = try await classes.setNoteDay(id: FakeClassesRepository.evening.id, saturday, centre: UUID())
        #expect(changed.noteDay == saturday)
        let students = FakeStudentsRepository(students: FakeStudentsRepository.seed)
        #expect(try await students.setNextStep(id: FakeStudentsRepository.dev, .stepBack).nextStep == .stepBack)
        #expect(try await students.setNextStep(id: FakeStudentsRepository.dev, nil).nextStep == nil)
    }
}

struct NotesCacheTests {
    @Test func theWeeksNotesRoundTripUnderTheCentre() throws {
        let centre = UUID()
        let cache = NotesCache(
            centre: centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        )
        #expect(cache.read().isEmpty)
        try cache.keep([ParentsSamples.artefact])
        #expect(cache.read() == [ParentsSamples.artefact])
        #expect(cache.url.lastPathComponent == "cache-\(centre.uuidString.lowercased())-notes.json")
    }
}

enum ParentsSamples {
    static let content = NoteContent(
        message: "नमस्ते रमेश जी", english: "Hello Ramesh", language: .hindi,
        weekMonday: Day(year: 2026, month: 10, day: 5)!,
        facts: [.init(label: "Taught", fact: "Chemical reactions: balancing equations", symbol: "book.closed")],
        generationID: UUID(uuidString: "99999999-9999-9999-9999-999999999991")
    )

    static let artefact = Artefact(
        id: UUID(), kind: .note, source: .made, title: "Dev's week", content: .note(content), photoPath: nil,
        studentID: FakeStudentsRepository.dev, planID: nil, regeneratedFrom: nil,
        madeAt: Date(timeIntervalSince1970: 1_791_000_000), generationID: content.generationID
    )
}
