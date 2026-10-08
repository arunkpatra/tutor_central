import Domain
import Foundation

struct ClassroomRow: Decodable {
    let id: UUID
    let name: String
    let subject: String?
    let monthlyFee: Int?
    let meetingDays: [Int]
    let startTime: String?
    let endTime: String?
    let archivedAt: Date?

    var classroom: Classroom {
        Classroom(
            id: id, name: name, subject: subject, monthlyFee: monthlyFee.map(Money.init(rupees:)),
            meetingDays: Set(meetingDays.compactMap(Weekday.init(rawValue:))),
            startTime: startTime.flatMap(TimeOfDay.init(iso:)), endTime: endTime.flatMap(TimeOfDay.init(iso:)),
            archivedAt: archivedAt
        )
    }
}
