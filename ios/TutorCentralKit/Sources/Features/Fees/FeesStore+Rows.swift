import Data
import Domain
import Foundation

/// A fee row's words: settled (and kept on this iPhone while offline), reminded, or the parent to ask.
extension FeesStore {
    func row(_ invoice: FeeInvoice) -> Row {
        let state = invoice.state(current: today.period)
        let student = register.student(invoice.studentID)
        let name = student?.name ?? ""
        guard !state.isSettled else {
            let kept = keptHere.contains(invoice.id)
            let line = (invoice.settledLine(calendar: calendar) ?? "")
                + (kept ? " · Kept on this iPhone until you're online" : "")
            return Row(
                invoice: invoice, name: name, line: line, lineTone: kept ? .due : nil, lineSymbol: nil, state: state,
                showsButtons: false
            )
        }
        if let reminded = logs.first(where: {
            $0.kind == .reminder && $0.studentID == invoice.studentID && $0.month == invoice.period
        }) {
            let day = Day(reminded.openedAt, calendar: calendar)
            return Row(
                invoice: invoice, name: name,
                line: day == today ? "Reminded today" : "Reminded \(day.shortWeekdayText)",
                lineTone: .ok, lineSymbol: "checkmark", state: state, showsButtons: true
            )
        }
        return Row(
            invoice: invoice, name: name, line: Self.parentLine(student) ?? "No parent details yet",
            lineTone: nil, lineSymbol: nil, state: state, showsButtons: true
        )
    }

    /// "Ramesh Kumar · +91 98848 43831": the parent's name and number, either alone, or nil with neither.
    static func parentLine(_ student: Student?) -> String? {
        let parts = [student?.parentName, student?.parentPhone?.display].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
