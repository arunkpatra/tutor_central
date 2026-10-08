import DesignSystem
import Domain
import SwiftUI

/// The student picker (P6-ProgressNote-StudentPicker): a floating sheet, large, with Cancel and "Student", the search
/// well, and an on-sheet card of the active students (avatar 40, name, class), the chosen one ticked in accentText and
/// a 24 pt ring on the others. One choice closes the sheet.
struct StudentPickerSheet: View {
    let students: [Student]
    let chosen: UUID?
    let className: (UUID?) -> String?
    let pick: (UUID) -> Void
    let close: () -> Void
    @State private var search = ""
    @State private var searching = false
    static var ring: CGFloat {
        24
    }

    static var ringWidth: CGFloat {
        1.5
    }

    private var shown: [Student] {
        let query = search.trimmingCharacters(in: .whitespaces)
        return query.isEmpty ? students : students.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Student", cancel: ("Cancel", close))
            SearchWell(text: $search, placeholder: "Search by name", isSearching: $searching)
            ScrollView {
                Card(.onSheet) {
                    VStack(spacing: 0) {
                        ForEach(shown) { student in
                            row(student, isLast: student.id == shown.last?.id)
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private func row(_ student: Student, isLast: Bool) -> some View {
        Button {
            pick(student.id)
        } label: {
            HStack(spacing: Tokens.rowPaddingDense) {
                Avatar(name: student.name)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(student.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(className(student.classID) ?? "No class")
                        .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if student.id == chosen {
                    Image(systemName: "checkmark")
                        .font(.system(size: Tokens.iconButton, weight: .semibold))
                        .foregroundStyle(Tokens.accentText.color)
                        .frame(width: Self.ring, height: Self.ring)
                } else {
                    Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Self.ringWidth)
                        .frame(width: Self.ring, height: Self.ring)
                }
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .pressable()
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
            }
        }
        .accessibilityAddTraits(student.id == chosen ? .isSelected : [])
    }
}
