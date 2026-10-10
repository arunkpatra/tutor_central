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
    let planGroups: Int?
    /// `{"3": {"groups": 2, "subjects": [...]}}`, by ISO weekday.
    let planPattern: [String: PlanPattern]?

    var classroom: Classroom {
        Classroom(
            id: id, name: name, subject: subject, monthlyFee: monthlyFee.map(Money.init(rupees:)),
            meetingDays: Set(meetingDays.compactMap(Weekday.init(rawValue:))),
            startTime: startTime.flatMap(TimeOfDay.init(iso:)), endTime: endTime.flatMap(TimeOfDay.init(iso:)),
            archivedAt: archivedAt, planGroups: planGroups,
            planPattern: (planPattern ?? [:]).reduce(into: [:]) { patterns, entry in
                if let raw = Int(entry.key), let day = Weekday(rawValue: raw) {
                    patterns[day] = entry.value
                }
            }
        )
    }
}
