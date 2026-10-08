import DesignSystem
import Domain
import SwiftUI

/// A place whose feature arrives in a later build, to P2-Later: one card that says so, with the build, under its
/// title in the navigation bar.
struct LaterView: View {
    let place: LaterPlace
    let build: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                Card {
                    VStack(spacing: Tokens.inline) {
                        FeatureTile(symbol: place.symbol)
                        Text(place.heading)
                            .typeStyle(Tokens.emptyTitle)
                            .foregroundStyle(Tokens.text.color)
                            .padding(.top, Tokens.fieldGap)
                        Text(place.line)
                            .typeStyle(Tokens.subhead)
                            .foregroundStyle(Tokens.text2.color)
                            .frame(maxWidth: Tokens.measureLine)
                        Chip(.neutral("Build \(build)")).padding(.top, Tokens.tileGap)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Tokens.emptyPadding)
                    .padding(.horizontal, Tokens.heroInset)
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, Tokens.sectionGap)
            .padding(.bottom, Tokens.contentBottom)
        }
        .background(Tokens.ground.color)
        .navigationTitle(place.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Every place that is "on the way" in this build, with the board's words.
enum LaterPlace: Hashable, Sendable {
    case scanRegister
    case studentFees
    /// Parent payments, until its screen lands with Phase 5's payments.
    case payments

    var title: String {
        switch self {
        case .studentFees: "Fees"
        case .scanRegister: "Scan register"
        case .payments: "Parent payments"
        }
    }

    var symbol: String {
        switch self {
        case .studentFees, .payments: "indianrupeesign"
        case .scanRegister: "doc.viewfinder"
        }
    }

    var heading: String {
        switch self {
        case .studentFees, .payments: "\(title) are on the way"
        case .scanRegister: "\(title) is on the way"
        }
    }

    var line: String {
        let opening = "This build has sign-in, your profile, Today and the register."
        let rest = switch self {
        case .payments: "Your UPI id, payment link and receipts arrive"
        case .scanRegister: "Photographing your paper register and reading it arrives"
        case .studentFees: "The fee ledger, reminders and receipts arrive"
        }
        return "\(opening) \(rest) in a later build on TestFlight."
    }
}
