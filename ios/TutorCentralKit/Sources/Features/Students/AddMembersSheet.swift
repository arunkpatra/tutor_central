import DesignSystem
import Domain
import SwiftUI

/// Add students to a class, to P3-ClassDetail-AddMembers: a checklist of everyone active who is not in it, with the
/// class they are in now, and the button that says how many.
public struct AddMembersSheet: View {
    let classroom: Classroom
    let candidates: [Student]
    let classNames: (UUID?) -> String
    let onAdd: ([UUID]) async -> Void
    let onClose: () -> Void
    @State private var selected: Set<UUID>
    @State private var saving = false
    /// P3-ClassDetail-AddMembers draws the sheet over the lower 59% of the screen; a longer list drags to large.
    static var boardFraction: CGFloat {
        0.6
    }

    public init(
        classroom: Classroom,
        candidates: [Student],
        classNames: @escaping (UUID?) -> String,
        preselected: Set<UUID> = [],
        onAdd: @escaping ([UUID]) async -> Void,
        onClose: @escaping () -> Void
    ) {
        self.classroom = classroom
        self.candidates = candidates
        self.classNames = classNames
        self.onAdd = onAdd
        self.onClose = onClose
        _selected = State(initialValue: preselected)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Add to \(classroom.name)", cancel: ("Cancel", onClose))
            ScrollView {
                if candidates.isEmpty {
                    EmptyState(
                        symbol: "person.2",
                        title: "Everyone is in this class",
                        line: "Add a student from the Students tab first."
                    )
                } else {
                    VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                        Card(.onSheet) {
                            VStack(spacing: 0) {
                                ForEach(Array(candidates.enumerated()), id: \.element.id) { index, student in
                                    ChecklistRow(
                                        initials: student.initials,
                                        name: student.name,
                                        detail: classNames(student.classID),
                                        isOn: binding(student.id)
                                    )
                                    .rowDivider(index < candidates.count - 1)
                                }
                            }
                        }
                        Text(
                            "A student moved from another class keeps a fee of their own; otherwise this class's fee "
                                + "applies from next month."
                        )
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.horizontal, Tokens.rowGapInner)
                    }
                }
            }
            Button(label, action: add)
                .buttonStyle(.primary(.sheet, loading: saving))
                .disabled(selected.isEmpty)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.rowPaddingHorizontal)
        .modifier(SheetToasts())
        .presentationDetents([.fraction(Self.boardFraction), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var label: String {
        switch selected.count {
        case 0: "Add students"
        case 1: "Add 1 student"
        default: "Add \(selected.count) students"
        }
    }

    private func binding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { selected.contains(id) },
            set: { on in
                if on {
                    selected.insert(id)
                } else {
                    selected.remove(id)
                }
            }
        )
    }

    private func add() {
        saving = true
        Task {
            await onAdd(Array(selected))
            saving = false
            onClose()
        }
    }
}
