import Domain
import Foundation
import Observation

@MainActor @Observable public final class StudentFormStore: Identifiable {
    public enum Mode: Sendable {
        case new
        case edit(Student)
        /// A row read from a paper register (P6-Scan-Review-Edit): kept on the device until Add.
        case fix(StudentDraft)
    }

    public let mode: Mode
    public private(set) var classes: [Classroom]
    /// How many students each class has, for the class menu's second line (P7-NewStudent-ClassMenu).
    public var memberCounts: [UUID: Int] = [:]
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
    // V2 (P10-NewStudent): the class, the school, the board from class 8, the parent's message language.
    public var classLevel: ClassLevel?
    public var schoolID: UUID? {
        didSet {
            // The school's board, when it has one and none is chosen yet.
            if schoolID != oldValue, board == nil, let school = schools.first(where: { $0.id == schoolID }) {
                board = school.board
            }
        }
    }

    public var board: Board?
    public var messageLanguage: MessageLanguage = .default
    /// The centre's schools for the school sheet, with each one's student count.
    public private(set) var schools: [School]
    public var schoolCounts: [UUID: Int]
    public private(set) var phoneError: String?

    public init(
        mode: Mode, classes: [Classroom], schools: [School] = [], schoolCounts: [UUID: Int] = [:], today: Day,
        defaultLanguage: MessageLanguage = .default
    ) {
        self.mode = mode
        self.classes = classes.filter { !$0.isArchived }.sorted { $0.name < $1.name }
        self.schools = schools.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        self.schoolCounts = schoolCounts
        self.today = today
        messageLanguage = defaultLanguage
        birthDate = Day(year: today.year - 12, month: today.month, day: min(today.day, 28))!
        let start: StudentDraft? = switch mode {
        case .new: nil
        case let .edit(student): StudentDraft(student)
        case let .fix(draft): draft
        }
        if let draft = start {
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
            classLevel = draft.classLevel
            schoolID = draft.schoolID
            board = draft.board
            messageLanguage = draft.messageLanguage
        } else {
            original = nil
        }
    }

    public var title: String {
        switch mode {
        case .new: "New student"
        case .edit: "Edit student"
        case .fix: "Fix this row"
        }
    }

    /// Fixing a row whose number was not read, until one is typed.
    public var phoneHelper: String? {
        guard case .fix = mode, digits.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return "Nothing was read for the number. Type it, or leave it empty and add it later."
    }

    public var classroom: Classroom? {
        classID.flatMap { id in classes.first { $0.id == id } }
    }

    public var classLabel: String {
        classroom?.name ?? "No batch yet"
    }

    /// New student needs the class; Edit and Fix this row do not (plan decision 5).
    public var requiresClass: Bool {
        if case .new = mode {
            true
        } else {
            false
        }
    }

    /// The Class tile's value; nil shows its placeholder, "Choose".
    public var classTitle: String? {
        classLevel?.title
    }

    /// Under the Class tile until a class is chosen (P10-NewStudent).
    public var classHelper: String? {
        classLevel == nil ? "LKG to class 10. The plan and the sheets follow it." : nil
    }

    /// The School tile's value; nil shows "Choose or add".
    public var schoolTitle: String? {
        schoolID.flatMap { id in schools.first { $0.id == id } }?.name
    }

    /// The Board row shows from class 8.
    public var showsBoard: Bool {
        classLevel?.expectsBoard == true
    }

    public var boardHelper: String {
        "Shown from class 8. The chapters follow the board's list."
    }

    /// "Notes to Neha are written in this language…" (P10-NewStudent-End): the parent's first name.
    public var languageHelper: String {
        let first = parentName.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? "the parent"
        return "Notes to \(first) are written in this language, with English beside them for you."
    }

    /// The school sheet's line under a school: "4 students · CBSE", "No students yet".
    public func schoolLine(_ school: School) -> String {
        let count = schoolCounts[school.id] ?? 0
        let students = switch count {
        case 0: "No students yet"
        case 1: "1 student"
        default: "\(count) students"
        }
        return [students, school.board?.title].compactMap(\.self).joined(separator: " · ")
    }

    /// A school made from the sheet's last row: chosen at once.
    public func schoolAdded(_ school: School) {
        schools.append(school)
        schools.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        schoolID = school.id
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
        if case let .fix(read) = mode, let fee = read.fee, typedFee == fee, let classFee {
            return "Read from the page. The batch fee is \(classFee.formatted) too."
        }
        return switch (classFee, feeText.isEmpty) {
        case (nil, true): "Leave empty to use the batch fee once a batch is chosen."
        case let (fee?, true): "Using the batch fee, \(fee.formatted). Type an amount to set one for this student."
        case let (fee?, false): "The batch fee is \(fee.formatted). This student pays this amount instead."
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
        draft.classLevel = classLevel
        draft.schoolID = schoolID
        draft.board = board
        draft.messageLanguage = messageLanguage
        return draft
    }

    public var isChanged: Bool {
        original.map { $0 != draft } ?? true
    }

    public var canSave: Bool {
        problems.isEmpty && feeError == nil && phoneError == nil && (isChanged || isFix)
            && (feeText.isEmpty || typedFee != nil)
    }

    /// A scanned row can be kept as it was read.
    private var isFix: Bool {
        if case .fix = mode {
            true
        } else {
            false
        }
    }

    public func select(classID: UUID?) {
        self.classID = classID
    }

    /// New class… from the menu, saved (P7-NewStudent-ClassMade): it joins the menu and is chosen; its fee is used.
    public func classAdded(_ classroom: Classroom) {
        classes = (classes.filter { $0.id != classroom.id } + [classroom]).sorted { $0.name < $1.name }
        select(classID: classroom.id)
    }

    /// "6 students", "1 student", "No students yet".
    public func membersLine(_ classID: UUID) -> String {
        switch memberCounts[classID] ?? 0 {
        case 0: "No students yet"
        case 1: "1 student"
        case let count: "\(count) students"
        }
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
        draft.problems(today: today, requiresClass: requiresClass)
    }

    private func message(_ problem: StudentDraft.Problem) -> String? {
        problems.contains(problem) ? problem
            .message : nil
    }
}
