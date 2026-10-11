import Data
import Domain
import Foundation

/// Share as CSV (P5-Reports-Export): the month's fees or attendance, or Progress for the span.
public extension ReportsStore {
    func export(_ segment: Segment) -> Export {
        switch segment {
        case .fees:
            let rows = invoices.map { invoice in
                let student = register.student(invoice.studentID)
                let reminded = logs.first { $0.kind == .reminder && $0.studentID == invoice.studentID }
                return FeesCSVRow(
                    student: student?.name ?? "", className: className(student), amount: invoice.amount,
                    state: invoice.state(current: current), paidOn: invoice.paidOn(calendar: calendar),
                    paidBy: invoice.paidMethod, remindedOn: reminded.map { Day($0.openedAt, calendar: calendar) }
                )
            }
            .sorted { $0.student.localizedStandardCompare($1.student) == .orderedAscending }
            return Export(fileName: FeesCSV.fileName(month), text: FeesCSV.make(rows))
        case .attendance:
            let rows = attendanceLines.map { line in
                AttendanceCSVRow(
                    student: line.name, className: line.className, present: line.present ?? 0, absent: line.absent ?? 0
                )
            }
            return Export(fileName: AttendanceCSV.fileName(month), text: AttendanceCSV.make(rows))
        case .progress:
            return Export(fileName: ProgressCSV.fileName(progressSpan), text: ProgressCSV.make(progressRows))
        }
    }

    /// The CSV in the temporary directory, for the share sheet; nil when it cannot be written.
    func exportFile(_ segment: Segment) -> URL? {
        let file = export(segment)
        let url = FileManager.default.temporaryDirectory.appending(path: file.fileName)
        do {
            try file.text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
