import Domain
import Foundation
import Testing
@testable import Data

struct ClassroomRowTests {
    @Test func decodesMeetingDaysAndTimes() throws {
        let json = Data("""
        [{"id":"33333333-3333-3333-3333-333333333331","name":"Class 10 Maths","subject":"Mathematics",
          "monthly_fee":1200,"meeting_days":[1,3,5],"start_time":"17:00:00","end_time":"18:00:00","archived_at":null}]
        """.utf8)
        let rows = try SupabaseClassesRepository.decoder.decode([ClassroomRow].self, from: json)
        let maths = rows[0].classroom
        #expect(maths.meetingDays == [.monday, .wednesday, .friday] && maths
            .meetingSummary == "Mon, Wed, Fri · 17:00–18:00")
        #expect(maths.monthlyFee == Money(rupees: 1200) && !maths.isArchived)
    }

    @Test func aBatchRowReadsItsPlanChoices() throws {
        let json = #"""
        {"id":"7a1f0000-0000-0000-0000-000000000009","name":"Evening batch","subject":"Science","monthly_fee":null,
         "meeting_days":[1,2],"start_time":"17:00","end_time":"18:30","archived_at":null,"plan_groups":2,
         "plan_pattern":{"3":{"groups":2,"subjects":["Science","Mathematics"]}}}
        """#
        let room = try SupabaseClassesRepository.decoder.decode(ClassroomRow.self, from: Data(json.utf8)).classroom
        #expect(room.planGroups == 2)
        #expect(room.planPattern[.wednesday]?.subjects == ["Science", "Mathematics"])
    }
}
