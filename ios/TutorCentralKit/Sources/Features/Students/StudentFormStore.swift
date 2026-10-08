import Domain
import Foundation
import Observation

@MainActor @Observable public final class StudentFormStore: Identifiable {
    public enum Mode: Sendable {
        case new
        case edit(Student)
    }

    public let mode: Mode
    public let classes: [Classroom]
    public let today: Day
    private let original: StudentDraft?

    public var name = ""
    public var parentName = ""
    public var digits = "" {
        didSet {
            if digits != oldValue {
                phoneError = nil
            }
        }
    }

    public var notes = ""
    public var classID: UUID?
    public var feeText = ""
    public var hasBirthDate = false
    public var birthDate: Day
    public var gender: Gender?
    public private(set) var phoneError: String?

    public init(mode: Mode, classes: [Classroom], today: Day) {
        self.mode = mode
        self.classes = classes.filter { !$0.isArchived }.sorted { $0.name < $1.name }
        self.today = today
        birthDate = Day(year: today.year - 12, month: today.month, day: min(today.day, 28))!
        if case let .edit(student) = mode {
            let draft = StudentDraft(student)
            original = draft
            name = draft.name
            parentName = draft.parentName
            digits = draft.parentDigits
            notes = draft.notes
            classID = draft.classID
            feeText = draft.fee.map(Self.text) ?? ""
            hasBirthDate = draft.dateOfBirth != nil
            birthDate = draft.dateOfBirth ?? birthDate
            gender = draft.gender
        } else {
            original = nil
        }
    }

    public var title: String {
        if case .edit = mode {
            "Edit student"
        } else {
            "New student"
        }
    }

    public var classroom: Classroom? {
        classID.flatMap { id in classes.first { $0.id == id } }
    }

    public var classLabel: String {
        classroom?.name ?? "No class"
    }

    public var classFee: Money? {
        classroom?.monthlyFee
    }

    public var feePlaceholder: String {
        classFee.map(Self.text) ?? "0"
    }

    public var typedFee: Money? {
        Money(typed: feeText)
    }

    public var notesCount: Int {
        notes.count
    }

    public var feeHelper: String {
        switch (classFee, feeText.isEmpty) {
        case (nil, true): "Pick a class to use its fee, or type one here."
        case let (fee?, true): "Using the class fee, \(fee.formatted). Type an amount to set one for this student."
        case let (fee?, false): "The class fee is \(fee.formatted). This student pays this amount instead."
        case (nil, false): "This student's own fee."
        }
    }

    public var feeError: String? {
        if !feeText.isEmpty, typedFee == nil {
            return "Type a whole number of rupees."
        }
        return problems.contains(.feeTooHigh) ? StudentDraft.Problem.feeTooHigh.message : nil
    }

    public var nameError: String? {
        message(.nameTooLong)
    }

    public var parentNameError: String? {
        message(.parentNameTooLong)
    }

    public var notesError: String? {
        message(.notesTooLong)
    }

    public var birthDateError: String? {
        message(.birthDateOut)
    }

    public var draft: StudentDraft {
        var draft = StudentDraft()
        draft.name = name
        draft.classID = classID
        draft.fee = typedFee
        draft.parentName = parentName
        draft.parentDigits = digits
        draft.dateOfBirth = hasBirthDate ? birthDate : nil
        draft.gender = gender
        draft.notes = notes
        return draft
    }

    public var isChanged: Bool {
        original.map { $0 != draft } ?? true
    }

    public var canSave: Bool {
        problems.isEmpty && feeError == nil && phoneError == nil && isChanged && (feeText.isEmpty || typedFee != nil)
    }

    public func select(classID: UUID?) {
        self.classID = classID
    }

    public func commitPhone() {
        phoneError = problems.contains(.phoneInvalid) ? StudentDraft.Problem.phoneInvalid.message : nil
    }

    public func toggle(_ gender: Gender) {
        self.gender = self.gender == gender ? nil : gender
    }

    /// 1500 → "1,500"; 100000 → "1,00,000": the field shows the Indian grouping without the sign.
    public static func text(_ money: Money) -> String {
        money.rupees.formatted(.number.locale(Locale(identifier: "en_IN")).grouping(.automatic))
    }

    private var problems: Set<StudentDraft.Problem> {
        draft.problems(today: today)
    }

    private func message(_ problem: StudentDraft.Problem) -> String? {
        problems.contains(problem) ? problem
            .message : nil
    }
}
