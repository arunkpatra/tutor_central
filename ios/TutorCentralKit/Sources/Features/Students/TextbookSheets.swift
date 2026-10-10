import DesignSystem
import Domain
import SwiftUI

/// The textbook's subject (plan decision 11): the student's subjects, the batch's, the common ones, then Add a subject.
struct SubjectSheet: View {
    @Bindable var store: TextbookStore
    let close: () -> Void
    @State private var newSubject = ""

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(title: "Subject", cancel: ("Cancel", close))
        } content: {
            Card(.onSheet) {
                VStack(spacing: 0) {
                    ForEach(store.subjects, id: \.self) { subject in
                        ChoiceRow(symbol: "book.closed", title: subject, line: nil, chosen: store.subject == subject) {
                            store.subject = subject
                            close()
                        }
                        .rowDivider()
                    }
                    AddFieldRow(placeholder: "Add a subject", text: $newSubject) {
                        let subject = newSubject.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !subject.isEmpty else { return }
                        store.subject = subject
                        close()
                    }
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}

/// A chapter (P10-Textbook-Chapter-Edit): its name, its skills in order with remove and add, Remove this chapter. Used
/// for a chapter read from the contents page and for a chapter of the tutor's own on the student's page.
struct ChapterSheet: View {
    let position: Int
    let initialName: String
    let initialSkills: [String]
    let onSave: (String, [String]) -> Void
    let onRemove: (() -> Void)?
    let close: () -> Void
    @State private var name = ""
    @State private var skills: [String] = []
    @State private var newSkill = ""

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(
                title: "Chapter \(position)", cancel: ("Cancel", close),
                save: .init("Save", enabled: !trimmedName.isEmpty, run: save)
            )
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                TextWell(label: "Chapter", text: $name, placeholder: "The chapter's name")
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Text("Skills, \(skills.count)").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    Card(.onSheet) {
                        VStack(spacing: 0) {
                            ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                                HStack(spacing: Tokens.inline) {
                                    Text(skill)
                                        .typeStyle(Tokens.rowTitle)
                                        .foregroundStyle(Tokens.text.color)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    IconButton(symbol: "xmark", label: "Remove \(skill)") { skills.remove(at: index) }
                                }
                                .padding(.vertical, Tokens.rowPaddingDense)
                                .padding(.horizontal, Tokens.rowPaddingHorizontal)
                                .rowDivider()
                            }
                            AddFieldRow(placeholder: "Add a skill", text: $newSkill) {
                                let skill = newSkill.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !skill.isEmpty else { return }
                                skills.append(skill)
                                newSkill = ""
                            }
                        }
                    }
                    FieldHelper("What the plan teaches and checks, one at a time, in this order.")
                }
                if let onRemove {
                    Button {
                        onRemove()
                        close()
                    } label: {
                        Text("Remove this chapter").typeStyle(Tokens.buttonStrong).foregroundStyle(Tokens.overdue.color)
                    }
                    .pressable()
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
        .onAppear {
            name = initialName
            skills = initialSkills
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        onSave(trimmedName, skills)
        close()
    }
}

/// Which chapter the textbook's sheet edits: one read, or a new one at the end.
enum ChapterEdit: Identifiable, Hashable {
    case existing(Int)
    case new(Int)

    var id: String {
        switch self {
        case let .existing(index): "existing-\(index)"
        case let .new(position): "new-\(position)"
        }
    }
}
