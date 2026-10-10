import Domain
import Foundation
import Supabase
import Testing
@testable import Data

struct TextbookRowTests {
    @Test func decodesATextbookWithItsChapters() throws {
        let json = Data("""
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718","school_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719",
          "class_level":"5","subject":"Mathematics","title":"Maths 5","publisher":null,"edition":"2026-27",
          "chapters":[{"position":1,"name":"Fractions","skills":["Halves","Quarters"]}]}]
        """.utf8)
        let rows = try SupabaseTextbooksRepository.decoder.decode([TextbookRow].self, from: json)
        let book = rows[0].textbook
        #expect(book.classLevel == .five && book.chapters == [
            TextbookChapter(position: 1, name: "Fractions", skills: ["Halves", "Quarters"]),
        ])
        #expect(book.publisher == nil && book.edition == "2026-27")
    }

    @Test func refusesAnUnknownClassLevel() {
        let json = Data(#"""
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60718","school_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60719",
          "class_level":"12","subject":"M","title":"T","chapters":[]}]
        """#.utf8)
        #expect(throws: (any Error).self) {
            try SupabaseTextbooksRepository.decoder.decode([TextbookRow].self, from: json)
        }
    }

    @Test func writesTheRowTheDatabaseTakes() {
        let book = Textbook(
            id: UUID(), schoolID: FakeSchoolsRepository.vidya.id, classLevel: .ukg, subject: "English",
            title: "English UKG", publisher: nil, edition: "2026-27",
            chapters: [TextbookChapter(position: 1, name: "Sounds", skills: ["a", "b", "c"])]
        )
        let values = SupabaseTextbooksRepository.values(book, centre: FakeSchoolsRepository.centre)
        #expect(values["class_level"] == .string("ukg") && values["publisher"] == .null)
        #expect(values["school_id"] == .string(FakeSchoolsRepository.vidya.id.uuidString.lowercased()))
        let skills: AnyJSON = .array([.string("a"), .string("b"), .string("c")])
        let chapter: AnyJSON = .object(["position": .integer(1), "name": .string("Sounds"), "skills": skills])
        #expect(values["chapters"] == .array([chapter]))
    }

    @Test func decodesASchoolAndAStudentsChaptersAndSkills() throws {
        let school = try SupabaseSchoolsRepository.decoder.decode(
            [SchoolRow].self,
            from: Data(#"[{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60731","name":"Vidya Niketan","board":"cbse"}]"#.utf8)
        )
        #expect(school.map(\.school) == [FakeSchoolsRepository.vidya])
        let chapters = try SupabaseTextbooksRepository.decoder.decode([ChapterRow].self, from: Data(#"""
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60741","subject":"Reading","position":1,"name":"Reading",
          "ladder":"reading"},
         {"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60742","subject":"EVS","position":1,"name":"My family","ladder":null}]
        """#.utf8))
        #expect(chapters.map(\.chapter.ladder) == [.reading, nil])
        let skills = try SupabaseTextbooksRepository.decoder.decode([SkillRow].self, from: Data(#"""
        [{"id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60751","chapter_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60741",
          "position":1,"name":"Letters","state":"secure","state_at":"2026-10-01T10:00:00.123456+00:00",
          "last_checked_at":null}]
        """#.utf8))
        #expect(skills[0].skill.state == .secure && skills[0].skill.lastCheckedAt == nil)
    }
}
