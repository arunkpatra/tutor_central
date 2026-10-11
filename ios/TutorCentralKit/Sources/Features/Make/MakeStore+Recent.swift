import Domain
import Foundation

/// Recent and History's rows (P10-Make): Make's artefacts and V1's results together, newest first.
public extension MakeStore {
    var rows: [Row] {
        let madeRows = made.map(row)
        let results = ai.history.map { generation in
            Row(
                symbol: generation.kind.symbol, title: generation.title(studentName: ai.studentName),
                line: generation.line(
                    className: ai.className, today: Day(now(), calendar: calendar), calendar: calendar
                ),
                opens: .generation(generation.id), at: generation.createdAt
            )
        }
        return (madeRows + results).sorted { $0.at > $1.at }
    }

    var recent: [Row] {
        Array(rows.prefix(3))
    }

    /// History's months, newest first, each with its rows.
    var months: [(period: Period, rows: [Row])] {
        let grouped = Dictionary(grouping: rows) { Period.containing($0.at, in: calendar.timeZone) }
        return grouped.keys.sorted { $0.isoDay > $1.isoDay }.map { (period: $0, rows: grouped[$0] ?? []) }
    }

    /// "Sheet · Group 1 · today, 16:40"; a student's full name ("Mock · Dev Kumar · …"); a brief names no one.
    private func row(_ artefact: Artefact) -> Row {
        let kind = MakeWords.kindTitle(artefact.kind)
        let target: String? = switch artefact.madeFor?.target {
        case _ where artefact.kind == .brief: nil
        case let .student(id)?: register.student(id)?.name ?? artefact.madeFor?.title
        case .some: artefact.madeFor?.title
        case nil: nil
        }
        let when = MakeWords.when(artefact.madeAt, now: now(), calendar: calendar)
        return Row(
            symbol: MakeWords.symbol(artefact.kind), title: artefact.title,
            line: [kind, target, when].compactMap(\.self).joined(separator: " · "), opens: .artefact(artefact.id),
            at: artefact.madeAt
        )
    }
}
