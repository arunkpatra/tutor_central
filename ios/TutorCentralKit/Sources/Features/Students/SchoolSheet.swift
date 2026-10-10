import DesignSystem
import Domain
import SwiftUI

/// The student form's school sheet (P10-NewStudent-School): search, the centre's schools with their counts and board,
/// one chosen, Add a school as the last row, and the footnote. Choosing closes it.
struct SchoolSheet: View {
    @Bindable var store: StudentFormStore
    let addSchool: ((String) async -> School?)?
    let close: () -> Void
    @State private var search = ""
    @State private var searching = false
    @State private var newName = ""
    @State private var adding = false

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: "School", cancel: ("Cancel", close))
        } content: {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                if store.schools.count > 1 {
                    SearchWell(text: $search, placeholder: "Search schools", isSearching: $searching)
                }
                Card(.onSheet) {
                    VStack(spacing: 0) {
                        ForEach(shown) { school in
                            ChoiceRow(
                                symbol: "building.columns", title: school.name, line: store.schoolLine(school),
                                chosen: store.schoolID == school.id
                            ) {
                                store.schoolID = school.id
                                close()
                            }
                            .rowDivider()
                        }
                        if addSchool != nil {
                            AddFieldRow(placeholder: "Add a school", text: $newName) { add() }
                        }
                    }
                }
                Text(
                    "One textbook photo per school and class serves everyone there. From class 8 the board is asked on "
                        + "the form."
                )
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var shown: [School] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return store.schools }
        return store.schools
            .filter { $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private func add() {
        guard !adding, let addSchool else { return }
        adding = true
        Task {
            if let made = await addSchool(newName) {
                store.schoolAdded(made)
                close()
            }
            adding = false
        }
    }
}
