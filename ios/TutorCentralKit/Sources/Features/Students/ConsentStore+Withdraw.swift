import DesignSystem
import Domain
import Foundation

/// The parent withdrew (P18-Consent-Change, -Withdraw, P18-Student-Withdrawn; plan/phase-18-plan.md decisions 15, 16):
/// the history under the row, the withdraw sheet's words and the write.
public extension ConsentStore {
    /// The history under the row once there is more than the first agreement, newest first (P18-Student-Withdrawn).
    var historyLines: [ConsentHistoryLine] {
        guard history.count > 1 else { return [] }
        return history.map { event in
            let day = Day(event.at, calendar: DayHeading.india).shortWeekdayText
            switch event.kind {
            case .withdrawn:
                return ConsentHistoryLine(
                    what: ["Withdrew", event.how.map(Self.withdrawnHow)].compactMap(\.self).joined(separator: " · "),
                    day: day
                )
            case .given:
                let parts = ["Agreed", event.how.map(Self.withdrawnHow), event.phone?.display]
                return ConsentHistoryLine(what: parts.compactMap(\.self).joined(separator: " · "), day: day)
            }
        }
    }

    var withdrawTitle: String {
        "\(parent) withdrew"
    }

    /// "Today, 12 Oct" or "Mon 5 Oct".
    var withdrewOnText: String {
        let today = Day(now(), calendar: DayHeading.india)
        return withdrawSheet.withdrewOn == today ? "Today, \(today.shortText)" : withdrawSheet.withdrewOn
            .shortWeekdayText
    }

    /// The days the withdrawal may name: the agreement's day to today.
    var withdrawDays: ClosedRange<Day> {
        let today = Day(now(), calendar: DayHeading.india)
        let agreed = student?.consent.map { Day($0.at, calendar: DayHeading.india) } ?? today
        return min(agreed, today) ... today
    }

    var withdrawStops: String {
        let their = pronoun
        return "Nothing about \(child) goes to the AI service. \(their.capitalized) notes, marking and messages to "
            + "\(their) parent stop; a note already written waits unsent. Sheets and sets for \(their) group go on, "
            + "without \(their) name."
    }

    var withdrawFootnote: String {
        "Kept in \(child)'s history: the day and how. What was made before stays in \(pronoun) record until you delete "
            + "\(object). You can record a new agreement any time."
    }

    /// Record the withdrawal (P18-Consent-Withdraw): how and the day, the consent cleared at once; offline refused in
    /// words and the sheet stays (D39).
    func withdraw() async -> Bool {
        guard await online() else {
            failure = OfflineRefusal.words(for: .consent)
            return false
        }
        let (how, day) = (withdrawSheet.how, withdrawSheet.withdrewOn)
        if let words = await register.withdrawConsent(studentID, how: how, on: day) {
            failure = words
            return false
        }
        let today = Day(now(), calendar: DayHeading.india)
        // As the server records it: now for today, noon for a day before.
        let start = day.date(in: DayHeading.india)
        let at = day == today ? now()
            : DayHeading.india.date(bySettingHour: 12, minute: 0, second: 0, of: start) ?? start
        history.insert(ConsentEvent(kind: .withdrawn, how: how, at: at, phone: nil), at: 0)
        return true
    }

    /// "in person", "on a call", "on WhatsApp": how a withdrawal came, and the history's agreement.
    internal nonisolated static func withdrawnHow(_ how: ConsentMethod) -> String {
        switch how {
        case .inPerson: "in person"
        case .call: "on a call"
        case .whatsapp: "on WhatsApp"
        }
    }
}
