import Domain
import Foundation
import Testing
@testable import Data

/// The fixtures are what the local stack answered as the seed's tutor (2026-10-08): the read, an insert, a done
/// update and the clear.
struct TaskRowTests {
    static let json = Data("""
    [{"id":"085598d5-6af4-4ee6-b41d-e0273b0f58b1","title":"Buy chalk and dusters","due_date":null,"done_at":null,\
    "created_at":"2026-10-08T09:26:01.859621+00:00"},
     {"id":"b6e1b39f-a27f-444b-80a7-b2219bc6f5da","title":"Call Dev's father about Saturday","due_date":"2026-10-10",\
    "done_at":null,"created_at":"2026-10-08T09:26:01.859621+00:00"}]
    """.utf8)

    @Test func decodesTasks() throws {
        let tasks = try SupabaseTasksRepository.decoder.decode([TaskRow].self, from: Self.json).map(\.task)
        #expect(tasks[0].title == "Buy chalk and dusters" && tasks[0].dueDate == nil && !tasks[0].isDone)
        #expect(tasks[1].dueDate == Day(year: 2026, month: 10, day: 10) && !tasks[1].isDone)
    }

    @Test func anInsertAndADoneAnswerDecode() throws {
        let inserted = Data("""
        {"id":"bd152afb-29dc-4780-8458-5c5e313c120b","title":"Print worksheets for Class 8","due_date":"2026-10-09",\
        "done_at":null,"created_at":"2026-10-08T09:27:30.424572+00:00"}
        """.utf8)
        #expect(try SupabaseTasksRepository.decoder.decode(TaskRow.self, from: inserted).task.dueDate?.day == 9)
        let done = Data("""
        {"id":"085598d5-6af4-4ee6-b41d-e0273b0f58b1","title":"Buy chalk and dusters","due_date":null,\
        "done_at":"2026-10-08T09:30:00+00:00","created_at":"2026-10-08T09:26:01.859621+00:00"}
        """.utf8)
        #expect(try SupabaseTasksRepository.decoder.decode(TaskRow.self, from: done).task.isDone)
    }

    @Test func theClearAnswersTheDeletedIDs() throws {
        let cleared = Data(#"[{"id":"085598d5-6af4-4ee6-b41d-e0273b0f58b1"}]"#.utf8)
        #expect(try SupabaseTasksRepository.decoder.decode([IDRow].self, from: cleared).count == 1)
    }
}
