import Domain
import Foundation

/// The weekly note's call (`/ai/make` kind `note`): the student, the parent, the class, the language and the week's
/// facts the phone worked out (Domain's `NoteWeek`).
public struct NoteRequest: Hashable, Sendable {
    /// The facts as the API's schema takes them: an empty fact is left out of the body.
    public struct Week: Hashable, Sendable {
        public let taught: [String]
        public let right: String?
        public let practise: [String]
        public let coming: [String]
        public let attendance: String?

        /// Held to the API's limits (api/src/schemas.ts, the note's `week`): a longer body is a 400 the tutor cannot
        /// act on.
        public init(taught: [String], right: String?, practise: [String], coming: [String], attendance: String?) {
            self.taught = taught.prefix(6).map { String($0.prefix(200)) }
            self.right = right.map { String($0.prefix(120)) }
            self.practise = practise.prefix(3).map { String($0.prefix(200)) }
            self.coming = coming.prefix(3).map { String($0.prefix(200)) }
            self.attendance = attendance.map { String($0.prefix(80)) }
        }

        public init(_ facts: NoteFacts) {
            self.init(
                taught: facts.taught, right: facts.right, practise: facts.practise, coming: facts.coming,
                attendance: facts.attendance
            )
        }
    }

    public let studentID: UUID
    public let studentName: String
    public let parentName: String?
    public let tutorName: String
    public let centreName: String
    public let classLevel: ClassLevel
    public let language: MessageLanguage
    public let weekMonday: Day
    public let week: Week
    /// The tutor's own words from Make's note (Phase 15), at most 300 scalars; nil when none.
    public let tutorSays: String?
    /// Write again's reason (D107): an instruction to the writer, never a sentence of the note.
    public var reason: String?

    public init(
        studentID: UUID, studentName: String, parentName: String?, tutorName: String, centreName: String,
        classLevel: ClassLevel, language: MessageLanguage, weekMonday: Day, week: Week, tutorSays: String? = nil
    ) {
        self.tutorSays = tutorSays
        self.studentID = studentID
        self.studentName = studentName
        self.parentName = parentName
        self.tutorName = tutorName
        self.centreName = centreName
        self.classLevel = classLevel
        self.language = language
        self.weekMonday = weekMonday
        self.week = week
    }

    /// The same request with the tutor's words, trimmed and held to the API's 300 (blank is none).
    public func saying(_ words: String) -> NoteRequest {
        let trimmed = words.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = trimmed
            .isEmpty ? nil : String(String.UnicodeScalarView(trimmed.unicodeScalars.prefix(APIContract.tutorSaysMax)))
        var said = NoteRequest(
            studentID: studentID, studentName: studentName, parentName: parentName, tutorName: tutorName,
            centreName: centreName, classLevel: classLevel, language: language, weekMonday: weekMonday, week: week,
            tutorSays: kept
        )
        said.reason = reason
        return said
    }

    /// The same request with Write again's reason (D107).
    public func asking(_ reason: String?) -> NoteRequest {
        var asked = self
        asked.reason = reason
        return asked
    }
}

/// Can-now-do's call (`/ai/make` kind `can_do`): the ladder's facts (Domain's `CanDoWeek`).
public struct CanDoRequest: Hashable, Sendable {
    public let studentID: UUID
    public let studentName: String
    public let parentName: String?
    public let tutorName: String
    public let centreName: String
    public let classLevel: ClassLevel
    public let language: MessageLanguage
    public let facts: CanDoFacts

    public init(
        studentID: UUID, studentName: String, parentName: String?, tutorName: String, centreName: String,
        classLevel: ClassLevel, language: MessageLanguage, facts: CanDoFacts
    ) {
        self.studentID = studentID
        self.studentName = studentName
        self.parentName = parentName
        self.tutorName = tutorName
        self.centreName = centreName
        self.classLevel = classLevel
        self.language = language
        self.facts = facts
    }
}

/// The not-on-track message's call in a parent's language (`/ai/make` kind `not_on_track`); English is the template.
public struct NotOnTrackRequest: Hashable, Sendable {
    public let studentID: UUID
    public let studentName: String
    public let parentName: String?
    public let tutorName: String
    public let centreName: String
    public let classLevel: ClassLevel
    public let language: MessageLanguage
    public let facts: NotOnTrackMessage.Facts

    public init(
        studentID: UUID, studentName: String, parentName: String?, tutorName: String, centreName: String,
        classLevel: ClassLevel, language: MessageLanguage, facts: NotOnTrackMessage.Facts
    ) {
        self.studentID = studentID
        self.studentName = studentName
        self.parentName = parentName
        self.tutorName = tutorName
        self.centreName = centreName
        self.classLevel = classLevel
        self.language = language
        self.facts = facts
    }
}

/// Marks from a photo (`/ai/read-marks`): one or two reduced photos, the student, the subjects kept for them.
public struct ReadMarksRequest: Hashable, Sendable {
    public let studentID: UUID
    public let studentName: String
    public let pages: [ImageUpload]
    public let subjects: [String]

    public init(studentID: UUID, studentName: String, pages: [ImageUpload], subjects: [String]) {
        self.studentID = studentID
        self.studentName = studentName
        self.pages = pages
        self.subjects = subjects
    }
}

/// The rows read, for the tutor to check before any mark is written.
public struct ReadMarksAnswer: Hashable, Sendable {
    public let generationID: UUID
    public let marks: [ReadMark]

    public init(generationID: UUID, marks: [ReadMark]) {
        self.generationID = generationID
        self.marks = marks
    }
}
