import Foundation

/// What the student form holds and checks (New student and Edit student boards). The phone is kept as the typed
/// national digits; `parentPhone` is the normalised number or nil.
public struct StudentDraft: Hashable, Sendable {
    public var name = ""
    public var classID: UUID?
    public var fee: Money?
    public var parentName = ""
    public var parentDigits = ""
    public var dateOfBirth: Day?
    public var gender: Gender?
    public var notes = ""
    // V2: the class, school, board (from class 8) and the parent's message language.
    public var classLevel: ClassLevel?
    public var schoolID: UUID?
    public var board: Board?
    public var messageLanguage: MessageLanguage = .default

    public static let nameLimit = 80
    public static let notesLimit = 2000
    public static let feeCeiling = Money(rupees: 100_000)
    public static let earliestBirthYear = 1950

    public enum Problem: Hashable, Sendable {
        case nameMissing, nameTooLong, parentNameTooLong, feeTooHigh, phoneInvalid, notesTooLong, birthDateOut
        case classMissing

        public var message: String {
            switch self {
            case .nameMissing: "The student needs a name."
            case .nameTooLong: "Keep the name under 80 characters."
            case .parentNameTooLong: "Keep the parent's name under 80 characters."
            case .feeTooHigh: "That's more than ₹1,00,000. Check the amount."
            case .phoneInvalid: PhoneNumber.invalidMessage
            case .notesTooLong: "Keep the notes under 2,000 characters."
            case .birthDateOut: "Check the date of birth."
            case .classMissing: "Choose the student's class."
            }
        }
    }

    public init() {}

    public init(_ student: Student) {
        name = student.name
        classID = student.classID
        fee = student.monthlyFee
        parentName = student.parentName ?? ""
        parentDigits = student.parentPhone?.nationalDigits ?? ""
        dateOfBirth = student.dateOfBirth
        gender = student.gender
        notes = student.notes ?? ""
        classLevel = student.classLevel
        schoolID = student.schoolID
        board = student.board
        messageLanguage = student.messageLanguage
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var trimmedParentName: String? {
        Self.nilIfEmpty(parentName)
    }

    public var trimmedNotes: String? {
        Self.nilIfEmpty(notes)
    }

    public var parentPhone: PhoneNumber? {
        PhoneNumber(indianDigits: parentDigits)
    }

    /// `requiresClass` is New student's rule (plan decision 5): a student edited from V1, or fixed from a scanned
    /// register, saves without a class.
    public func problems(today: Day, requiresClass: Bool = false) -> Set<Problem> {
        var found = Set<Problem>()
        if requiresClass, classLevel == nil {
            found.insert(.classMissing)
        }
        if trimmedName.isEmpty {
            found.insert(.nameMissing)
        }
        if trimmedName.storedCount > Self.nameLimit {
            found.insert(.nameTooLong)
        }
        if (trimmedParentName?.storedCount ?? 0) > Self.nameLimit {
            found.insert(.parentNameTooLong)
        }
        if let fee, fee > Self.feeCeiling {
            found.insert(.feeTooHigh)
        }
        if !parentDigits.trimmingCharacters(in: .whitespaces).isEmpty,
           parentPhone == nil {
            found.insert(.phoneInvalid)
        }
        if (trimmedNotes?.storedCount ?? 0) > Self.notesLimit {
            found.insert(.notesTooLong)
        }
        if let dateOfBirth,
           dateOfBirth > today || dateOfBirth.year < Self.earliestBirthYear {
            found.insert(.birthDateOut)
        }
        return found
    }

    public func isValid(today: Day, requiresClass: Bool = false) -> Bool {
        problems(today: today, requiresClass: requiresClass).isEmpty
    }

    private static func nilIfEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
