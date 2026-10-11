import Data
import Domain
import Foundation

/// Not on track (P10-Student-NotOnTrack, P10-NextStep, P10-NotOnTrack-Message, P10-Today-NotOnTrack): Friday 9 October
/// at 16:35, the Evening batch before its class. Dev is not on track since this morning, his parent (Hindi) agreed and
/// has not been told; Meher and Sahil on track, Nikhil to watch.
extension Fixtures {
    static let notOnTrackStates: Set<LaunchState> = [
        .studentNotOnTrack, .studentNextStep, .studentTellParent, .todayNotOnTrack,
    ]

    static var notOnTrackClock: Date {
        india(day: 9, hour: 16, minute: 35)
    }

    static var notOnTrackStudents: [Student] {
        planStudents.map { student in
            var changed = student
            if student.id == FakeStudentsRepository.dev {
                changed.trackSince = india(day: 9, hour: 8, minute: 0)
                changed.trackReasons = [
                    "Balancing equations: 3 of 10 on the mock and 1 of 6 checks right over three weeks",
                    "Absent twice in four weeks", "Homework not done three times running",
                ]
                changed.messageLanguage = .hindi
            }
            return changed
        }
    }
}
