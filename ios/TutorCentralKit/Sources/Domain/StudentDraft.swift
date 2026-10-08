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

    public static let nameLimit = 80
    public static let notesLimit = 2000
    public static let feeCeiling = Money(rupees: 100_000)
    public static let earliestBirthYear = 1950

    public enum Problem: Hashable, Sendable {
        case nameMissing, nameTooLong, parentNameTooLong, feeTooHigh, phoneInvalid, notesTooLong, birthDateOut

        public var message: String {
            switch self {
            case .nameMissing: "The student needs a name."
            case .nameTooLong: "Keep the name under 80 characters."
            case .parentNameTooLong: "Keep the parent's name under 80 characters."
            case .feeTooHigh: "That's more than ₹1,00,000. Check the amount."
            case .phoneInvalid: PhoneNumber.invalidMessage
            case .notesTooLong: "Keep the notes under 2,000 characters."
            case .birthDateOut: "Check the date of birth."
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

    public func problems(today: Day) -> Set<Problem> {
        var found = Set<Problem>()
        if trimmedName.isEmpty {
            found.insert(.nameMissing)
        }
        if trimmedName.count > Self.nameLimit {
            found.insert(.nameTooLong)
        }
        if (trimmedParentName?.count ?? 0) > Self.nameLimit {
            found.insert(.parentNameTooLong)
        }
        if let fee, fee > Self.feeCeiling {
            found.insert(.feeTooHigh)
        }
        if !parentDigits.trimmingCharacters(in: .whitespaces).isEmpty,
           parentPhone == nil {
            found.insert(.phoneInvalid)
        }
        if (trimmedNotes?.count ?? 0) > Self.notesLimit {
            found.insert(.notesTooLong)
        }
        if let dateOfBirth,
           dateOfBirth > today || dateOfBirth.year < Self.earliestBirthYear {
            found.insert(.birthDateOut)
        }
        return found
    }

    public func isValid(today: Day) -> Bool {
        problems(today: today).isEmpty
    }

    private static func nilIfEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
