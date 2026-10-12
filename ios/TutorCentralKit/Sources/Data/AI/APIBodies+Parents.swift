import Domain
import Foundation

// The parents' bodies (api/src/schemas.ts, Phase 14), held to the API's limits on the app side (ios/CLAUDE.md): a
// refusal would read as a connection fault to the tutor.

struct MakeNoteBody: Encodable {
    struct Week: Encodable {
        let monday: String
        let taught: [String]
        let right: String?
        let practise: [String]
        let coming: [String]
        let attendance: String?
    }

    let kind = "note"
    let centreId: String
    let studentId: String
    let studentName: String
    let tutorName: String
    let parentName: String?
    let centreName: String
    let classLevel: String
    let language: String
    let week: Week
    /// Left out of the body when nil (Make's note only).
    let tutorSays: String?

    init(_ request: NoteRequest, centre: UUID) {
        tutorSays = request.tutorSays
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        studentName = String(request.studentName.prefix(80))
        tutorName = String(request.tutorName.prefix(80))
        parentName = request.parentName.map { String($0.prefix(80)) }
        centreName = String(request.centreName.prefix(120))
        classLevel = request.classLevel.rawValue
        language = request.language.rawValue
        let facts = request.week
        week = Week(
            monday: request.weekMonday.iso, taught: Self.cut(
                facts.taught,
                count: APIContract.noteTaughtMax,
                length: APIContract.noteItemLength
            ),
            right: facts.right.map { String($0.prefix(120)) }, practise: Self.cut(
                facts.practise,
                count: APIContract.notePractiseMax,
                length: APIContract.noteItemLength
            ),
            coming: Self.cut(facts.coming, count: APIContract.noteComingMax, length: APIContract.noteComingLength),
            attendance: facts.attendance.map { String($0.prefix(80)) }
        )
    }

    static func cut(_ items: [String], count: Int, length: Int) -> [String] {
        items.prefix(count).map { String($0.prefix(length)) }
    }
}

struct MakeCanDoBody: Encodable {
    struct MovedUp: Encodable {
        let area: String
        let step: String
    }

    struct Ladder: Encodable {
        let movedUp: [MovedUp]
        let canDo: [String]
        let atHome: String
        let next: [String]
    }

    let kind = "can_do"
    let centreId: String
    let studentId: String
    let studentName: String
    let tutorName: String
    let parentName: String?
    let centreName: String
    let classLevel: String
    let language: String
    let ladder: Ladder

    init(_ request: CanDoRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        studentName = String(request.studentName.prefix(80))
        tutorName = String(request.tutorName.prefix(80))
        parentName = request.parentName.map { String($0.prefix(80)) }
        centreName = String(request.centreName.prefix(120))
        classLevel = request.classLevel.rawValue
        language = request.language.rawValue
        let f = request.facts
        ladder = Ladder(
            movedUp: f.movedUp.prefix(3).map { MovedUp(area: $0.area.rawValue, step: String($0.step.prefix(40))) },
            canDo: MakeNoteBody.cut(f.canDo, count: APIContract.canDoMax, length: APIContract.canDoLength),
            atHome: String(f.atHome.prefix(APIContract.canDoAtHomeLength)),
            next: MakeNoteBody.cut(f.next, count: APIContract.canDoNextMax, length: APIContract.canDoNextLength)
        )
    }
}

struct MakeNotOnTrackBody: Encodable {
    let kind = "not_on_track"
    let centreId: String
    let studentId: String
    let studentName: String
    let tutorName: String
    let parentName: String?
    let centreName: String
    let classLevel: String
    let language: String
    let hard: [String]
    let reasons: [String]
    let doing: String
    let atHome: String?

    init(_ request: NotOnTrackRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        studentName = String(request.studentName.prefix(80))
        tutorName = String(request.tutorName.prefix(80))
        parentName = request.parentName.map { String($0.prefix(80)) }
        centreName = String(request.centreName.prefix(120))
        classLevel = request.classLevel.rawValue
        language = request.language.rawValue
        let f = request.facts
        hard = MakeNoteBody.cut(f.hard, count: APIContract.notOnTrackHardMax, length: APIContract.notOnTrackHardLength)
        reasons = MakeNoteBody.cut(
            f.reasons, count: APIContract.notOnTrackReasonsMax, length: APIContract.notOnTrackReasonLength
        )
        doing = String(f.doing.prefix(200))
        atHome = f.atHome.map { String($0.prefix(200)) }
    }
}

struct ReadMarksBody: Encodable {
    let centreId: String
    let studentId: String
    let studentName: String
    let pages: [ImageBody]
    let subjects: [String]

    init(_ request: ReadMarksRequest, centre: UUID) {
        centreId = centre.uuidString.lowercased()
        studentId = request.studentID.uuidString.lowercased()
        studentName = String(request.studentName.prefix(80))
        pages = request.pages.prefix(APIContract.readMarksPagesMax).map(ImageBody.init)
        subjects = MakeNoteBody.cut(
            request.subjects, count: APIContract.readMarksSubjectsMax, length: APIContract.subjectLength
        )
    }
}

/// The rows as the API answers them: a null date as nil, a fractional score rounded (as the marks row reads it).
struct ReadMarksResult: Decodable {
    struct Row: Decodable {
        let subject: String
        let test: String
        let date: String?
        let score: Double
        let max: Double
    }

    let marks: [Row]

    var read: [ReadMark] {
        marks.map {
            ReadMark(
                subject: $0.subject, test: $0.test, date: $0.date.flatMap(Day.init(iso:)),
                score: Int($0.score.rounded()), max: Int($0.max.rounded())
            )
        }
    }
}
