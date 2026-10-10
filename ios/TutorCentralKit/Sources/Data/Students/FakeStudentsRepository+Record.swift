import Domain
import Foundation

extension FakeStudentsRepository {
    /// The V2 record of the fixtures (plan decision 19, the 10.2 boards): Hemanth, Akshita and Ananya in class 10 at
    /// Vidya Niketan (CBSE), Hemanth on watch since Friday 2 October; Dev, Meher and Nikhil in class 8; Riya in class 5
    /// at Vidya Niketan, joined Monday 5 October, not known yet; Sahil in class 2 on the ladder. Bir Bikram Singh and
    /// Lakshmi Menon stay as V1 made them.
    nonisolated static func withRecord(_ student: Student) -> Student {
        var changed = student
        let india = DayHeading.india
        let at = { (day: Int, hour: Int) in
            india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour)) ?? Date()
        }
        switch student.name {
        case "Hemanth Reddy":
            changed.classLevel = .ten
            changed.schoolID = FakeSchoolsRepository.vidya.id
            changed.board = .cbse
            changed.gender = .male
            changed.trackStatus = .watch
            changed.trackReasons = ["5 of 9 checks right over three weeks", "Absent 2 times in four weeks"]
            changed.trackSince = at(2, 18)
        case "Akshita Rao", "Ananya Iyer":
            changed.classLevel = .ten
            changed.schoolID = FakeSchoolsRepository.vidya.id
            changed.board = .cbse
            changed.trackStatus = .onTrack
            changed.trackSince = at(2, 18)
        case "Dev Kumar", "Meher Shah", "Nikhil Das":
            changed.classLevel = .eight
        case "Riya Sharma":
            changed.classLevel = .five
            changed.schoolID = FakeSchoolsRepository.vidya.id
            changed.gender = .female
            changed.joinedAt = at(5, 16)
        case "Sahil Verma":
            changed.classLevel = .two
            changed.gender = .male
        default:
            break
        }
        return changed
    }
}
