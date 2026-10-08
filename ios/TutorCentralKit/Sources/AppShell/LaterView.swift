import DesignSystem
import Domain
import SwiftUI

/// A place whose feature arrives in a later build, to P2-Later: its title, then one card that says so, with the
/// build. Used for the four tabs past Today and for Today's actions that lead to a later screen.
struct LaterView: View {
    let place: LaterPlace
    let build: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                if place.isTab {
                    Text(place.title)
                        .typeStyle(Tokens.display)
                        .foregroundStyle(Tokens.text.color)
                        .accessibilityAddTraits(.isHeader)
                }
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
            .padding(.top, place.isTab ? Tokens.pageTop - topInset : Tokens.sectionGap)
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .navigationTitle(place.isTab ? "" : place.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(place.isTab ? .hidden : .automatic, for: .navigationBar)
    }

    @State private var topInset: CGFloat = 0
}

/// Every place that is "on the way" in this build, with the board's words.
enum LaterPlace: Hashable, Sendable {
    case tab(AppTab)
    case scanRegister
    case studentFees

    var isTab: Bool {
        if case .tab = self {
            true
        } else {
            false
        }
    }

    var title: String {
        switch self {
        case .tab(.today): "Today"
        case .tab(.students): "Students"
        case .tab(.fees): "Fees"
        case .tab(.attendance): "Attendance"
        case .tab(.more): "More"
        case .scanRegister: "Scan register"
        case .studentFees: "Fees"
        }
    }

    var symbol: String {
        switch self {
        case .tab(.today): "sun.max"
        case .tab(.students): "person.2"
        case .tab(.fees): "indianrupeesign"
        case .tab(.attendance): "checkmark.circle"
        case .scanRegister: "doc.viewfinder"
        case .studentFees: "indianrupeesign"
        case .tab(.more): "ellipsis"
        }
    }

    var heading: String {
        switch self {
        case .tab(.students), .tab(.fees), .studentFees: "\(title) are on the way"
        default: "\(title) is on the way"
        }
    }

    var line: String {
        let opening = "This build has sign-in, your profile, Today and the register."
        let rest = switch self {
        case .tab(.students): "Students, classes and the register scan arrive"
        case .tab(.fees): "Fees, reminders and receipts arrive"
        case .tab(.attendance): "Marking attendance and its history arrive"
        case .tab(.more): "Schedule, classes, reports and the AI tools arrive"
        case .tab(.today): "The schedule arrives"
        case .scanRegister: "Photographing your paper register and reading it arrives"
        case .studentFees: "The fee ledger, reminders and receipts arrive"
        }
        return "\(opening) \(rest) in a later build on TestFlight."
    }
}
