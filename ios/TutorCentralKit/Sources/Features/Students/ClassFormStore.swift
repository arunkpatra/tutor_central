import DesignSystem
import Domain
import Foundation
import Observation

@MainActor @Observable public final class ClassFormStore: Identifiable {
    public enum Mode: Sendable {
        case new
        case edit(Classroom)
    }

    public static let defaultStart = TimeOfDay(hour: 17, minute: 0)!
    public let mode: Mode
    private let original: ClassroomDraft?
    public var name = ""
    public var subject = ""
    public var feeText = ""
    public var days: Set<Weekday> = []
    public private(set) var startTime: TimeOfDay?
    public private(set) var endTime: TimeOfDay?

    public init(mode: Mode) {
        self.mode = mode
        if case let .edit(classroom) = mode {
            let draft = ClassroomDraft(classroom)
            original = draft
            name = draft.name
            subject = draft.subject
            feeText = draft.fee.map(StudentFormStore.text) ?? ""
            days = draft.meetingDays
            startTime = draft.startTime
            endTime = draft.endTime
        } else {
            original = nil
        }
    }

    public var title: String {
        if case .edit = mode {
            "Edit class"
        } else {
            "New class"
        }
    }

    public var feeHelper: String {
        if case .edit = mode {
            "Changing it changes the fee of every student on the class fee, from next month's bill."
        } else {
            "Students you add to this class start at this fee."
        }
    }

    public var everyDay: Bool {
        get { days.count == Weekday.allCases.count }
        set { days = newValue ? Set(Weekday.allCases) : [] }
    }

    public var dayItems: [DayPicker.Item] {
        Weekday.allCases.map { DayPicker.Item(
            id: $0.rawValue,
            initial: $0.initial,
            name: $0.name
        ) }
    }

    public var daySelection: Set<Int> {
        get { Set(days.map(\.rawValue)) }
        set { days = Set(newValue.compactMap(Weekday.init(rawValue:))) }
    }

    public var draft: ClassroomDraft {
        var draft = ClassroomDraft()
        draft.name = name
        draft.subject = subject
        draft.fee = Money(typed: feeText)
        draft.meetingDays = days
        draft.startTime = startTime
        draft.endTime = endTime
        return draft
    }

    public var summary: String {
        Classroom(
            id: UUID(),
            name: name,
            subject: nil,
            monthlyFee: nil,
            meetingDays: days,
            startTime: startTime,
            endTime: endTime,
            archivedAt: nil
        ).meetingSummary
    }

    public var feeError: String? {
        if !feeText.isEmpty, Money(typed: feeText) == nil {
            return "Type a whole number of rupees."
        }
        return draft.problems.contains(.feeTooHigh) ? ClassroomDraft.Problem.feeTooHigh.message : nil
    }

    public var nameError: String? {
        draft.problems.contains(.nameTooLong) ? ClassroomDraft.Problem.nameTooLong.message : nil
    }

    public var timeError: String? {
        draft.problems.contains(.endNotAfterStart) ? ClassroomDraft.Problem.endNotAfterStart.message : nil
    }

    public var isChanged: Bool {
        original.map { $0 != draft } ?? true
    }

    public var canSave: Bool {
        draft.isValid && feeError == nil && isChanged
    }

    public func setStart(_ time: TimeOfDay?) {
        startTime = time
        if let time, endTime == nil {
            endTime = TimeOfDay(hour: min(time.hour + 1, 23), minute: time.minute)
        }
        if time == nil {
            endTime = nil
        }
    }

    public func setEnd(_ time: TimeOfDay?) {
        endTime = time
    }
}
