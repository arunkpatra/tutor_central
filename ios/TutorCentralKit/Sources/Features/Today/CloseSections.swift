import DesignSystem
import Domain
import SwiftUI

/// The close student card (components.md 10.3): the head (avatar 36, the name, a catch-up line in `due`, the attendance
/// pill), the eyebrow and the check rows or the placement's, a rule, the homework switch row. Absent: the head and one
/// line.
struct CloseStudentCard: View {
    let store: CloseStore
    let index: Int

    private var student: CloseStudent {
        store.students[index]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            if student.present {
                checks
                Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
                    .padding(.leading, Tokens.rowPaddingHorizontal)
                homework
            } else {
                Text("Marked absent. The checks and homework wait; a catch-up line joins the next plan.")
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .padding(.bottom, Tokens.rowPaddingDense)
            }
        }
        .surface(radius: Tokens.radiusCard)
    }

    private var head: some View {
        Button {
            store.toggle(index)
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.rowPaddingDense) {
                Avatar(initials: student.initials, size: MessageSheet.avatarSize)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(student.name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    if let catchUp = student.catchUp {
                        Text(catchUp).typeStyle(Tokens.caption).foregroundStyle(Tokens.due.color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                AttendancePill(present: student.present)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityLabel(student.name)
        .accessibilityValue(student.present ? "Present" : "Absent")
        .accessibilityHint(student.present ? "Marks absent" : "Marks present")
        .accessibilityAddTraits(.isToggle)
    }

    @ViewBuilder private var checks: some View {
        switch student.checks {
        case .loading:
            eyebrow("Check · 3 questions")
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.rowPaddingDense)
        case let .rows(rows):
            eyebrow(rows.count == 1 ? "Check · 1 question" : "Check · \(rows.count) questions")
            ForEach(rows.indices, id: \.self) { row in
                CheckRow(
                    skill: rows[row].skill, question: rows[row].question, answer: rows[row].answer,
                    tap: Binding(get: { rows[row].tap }, set: { store.setTap(index, row, $0) })
                )
                .rowDivider(row != rows.count - 1)
            }
        case let .placement(subjects):
            eyebrow("Placement · a few questions per subject")
            ForEach(subjects.indices, id: \.self) { subject in
                placementRows(subjects[subject], at: subject)
            }
        case .none:
            line("No book yet, so no checks. Add one from \(student.firstName)'s page.")
        case .skipped:
            EmptyView()
        case let .failed(words):
            failed(words)
        }
    }

    @ViewBuilder private func placementRows(_ subject: PlacementSubject, at position: Int) -> some View {
        if let failure = subject.failure {
            failed("\(subject.title): \(failure)")
        } else {
            ForEach(subject.rows.indices, id: \.self) { row in
                CheckRow(
                    skill: subject.rows[row].skill, question: subject.rows[row].question,
                    answer: subject.rows[row].answer,
                    tap: Binding(
                        get: { subject.rows[row].tap },
                        set: { store.setPlacementTap(index, subject: position, row: row, $0) }
                    )
                )
                .rowDivider()
            }
        }
    }

    private var homework: some View {
        HStack(spacing: Tokens.inline) {
            Text(store.homeworkLabel(student)).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Switch(
                isOn: Binding(get: { student.homeworkGiven }, set: { store.setHomework(index, given: $0) }),
                label: store.homeworkLabel(student)
            )
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .growsWithText()
    }

    private func eyebrow(_ text: String) -> some View {
        Eyebrow(text)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .padding(.top, Tokens.rowGapInner)
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .typeStyle(Tokens.footnote)
            .foregroundStyle(Tokens.text2.color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .padding(.bottom, Tokens.rowPaddingDense)
    }

    /// The checks could not be made: the words in place with Try again; attendance and homework still close.
    private func failed(_ words: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
            Label(words, systemImage: "exclamationmark.circle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Try again") { Task { await store.retryChecks(for: index) } }
                .buttonStyle(.quiet(emphasised: true))
        }
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .padding(.bottom, Tokens.rowPaddingDense)
    }
}
