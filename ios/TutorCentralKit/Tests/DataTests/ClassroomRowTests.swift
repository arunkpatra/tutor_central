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
}
