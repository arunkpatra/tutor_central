import Foundation

/// The parent-facing texts behind Remind and the receipt (P5-Remind, P5-Receipt; components.md, Phase 5 parts): plain
/// and polite, the child, the month, the amount, the UPI id or link at the end, the tutor and the centre as the
/// signature (as the absence alert). `AbsenceMessage.whatsAppURL` carries it.
public struct FeeMessage: Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case reminder
        case receipt(method: MonthFee.PaidMethod, day: Day)
    }

    public let kind: Kind
    public let parentName: String?
    public let studentName: String
    public let month: Period
    public let amount: Money
    public let upiID: String?
    public let paymentLink: String?
    public let tutorName: String?
    public let centreName: String

    public init(
        kind: Kind, parentName: String?, studentName: String, month: Period, amount: Money, upiID: String?,
        paymentLink: String?, tutorName: String?, centreName: String
    ) {
        self.kind = kind
        self.parentName = parentName
        self.studentName = studentName
        self.month = month
        self.amount = amount
        self.upiID = upiID
        self.paymentLink = paymentLink
        self.tutorName = tutorName
        self.centreName = centreName
    }

    public var text: String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        let body: String
        switch kind {
        case .reminder:
            let pay: String? = switch (upiID, paymentLink) {
            case let (id?, link?): "You can pay by UPI to \(id) or through this link: \(link)."
            case let (id?, nil): "You can pay by UPI to \(id)."
            case let (nil, link?): "You can pay through this link: \(link)."
            case (nil, nil): nil
            }
            body = [
                "\(greeting) \(child)'s fee of \(amount.formatted) for \(month.monthName) is due.",
                pay,
                "Thank you.",
            ]
            .compactMap(\.self).joined(separator: " ")
        case let .receipt(method, day):
            let by = switch method {
            case .upi: " by UPI"
            case .cash: " by cash"
            case .other: ""
            }
            let what = "\(child)'s \(month.monthName) fee"
            body = "\(greeting) received \(amount.formatted)\(by) on \(day.shortText) for \(what). Thank you."
        }
        return "\(body)\n\n\(signature)"
    }
}
