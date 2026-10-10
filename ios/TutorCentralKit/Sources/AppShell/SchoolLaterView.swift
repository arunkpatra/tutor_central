import DesignSystem
import SwiftUI

/// The School tab until Phase 13 builds its content (the 10.1 note): P2-Later's card with P10-School-Empty's symbol,
/// so no button on screen does nothing.
struct SchoolLaterView: View {
    let build: String
    static let line = "Tests, homework, notices and holidays from your students' schools arrive here in a later "
        + "build."
    @State private var topInset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                Text("School")
                    .typeStyle(Tokens.display)
                    .singleLineTitle()
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                Card {
                    VStack(spacing: Tokens.inline) {
                        FeatureTile(symbol: "building.columns")
                        Text("School is on the way")
                            .typeStyle(Tokens.emptyTitle)
                            .foregroundStyle(Tokens.text.color)
                            .padding(.top, Tokens.fieldGap)
                        Text(Self.line)
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
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
    }
}
