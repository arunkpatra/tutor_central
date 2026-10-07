import DesignSystem
import Domain
import SwiftUI

/// A place whose feature arrives in a later build, to P2-Later: its title, then one card that says so, with the
/// build. Used for the four tabs past Today and for Today's actions that lead to a later screen.
struct LaterView: View {
    let place: LaterPlace
    let build: String
    static var tile: CGFloat {
        56
    }

    static var symbol: CGFloat {
        28
    }

    static var lineWidth: CGFloat {
        280
    }

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
                        Image(systemName: place.symbol)
                            .font(.system(size: Self.symbol))
                            .foregroundStyle(Tokens.accentText.color)
                            .frame(width: Self.tile, height: Self.tile)
                            .background(
                                Tokens.accentTint.color,
                                in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous)
                            )
                            .accessibilityHidden(true)
                        Text(place.heading)
                            .typeStyle(Tokens.emptyTitle)
                            .foregroundStyle(Tokens.text.color)
                            .padding(.top, Tokens.fieldGap)
                        Text(place.line)
                            .typeStyle(Tokens.subhead)
                            .foregroundStyle(Tokens.text2.color)
                            .frame(maxWidth: Self.lineWidth)
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
    case tasks
    case schedule

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
        case .tasks: "Tasks"
        case .schedule: "Schedule"
        }
    }

    var symbol: String {
        switch self {
        case .tab(.today): "sun.max"
        case .tab(.students): "person.2"
        case .tab(.fees): "indianrupeesign"
        case .tab(.attendance), .tasks: "checkmark.circle"
        case .tab(.more): "ellipsis"
        case .schedule: "calendar"
        }
    }

    var heading: String {
        switch self {
        case .tab(.students), .tab(.fees), .tasks: "\(title) are on the way"
        default: "\(title) is on the way"
        }
    }

    var line: String {
        let opening = "This build has sign-in, your profile and the Today screen."
        let rest = switch self {
        case .tab(.students): "Students, classes and the register scan arrive"
        case .tab(.fees): "Fees, reminders and receipts arrive"
        case .tab(.attendance): "Marking attendance and its history arrive"
        case .tab(.more): "Schedule, classes, reports and the AI tools arrive"
        case .tasks: "Tasks arrive"
        case .schedule, .tab(.today): "The schedule arrives"
        }
        return "\(opening) \(rest) in a later build on TestFlight."
    }
}
