import DesignSystem
import Domain
import SwiftUI

/// A row of the date and class card: the label in body, the value in accentText with `chevron.up.chevron.down`, 50
/// high (P4-Attendance-Mark-Fresh).
struct PickerLine: View {
    let label: String
    let value: String
    let action: () -> Void
    static var height: CGFloat {
        ButtonSize.card.rawValue
    }

    var body: some View {
        Button(action: action) {
            AdaptiveRow {
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                AdaptiveSpacer(minLength: Tokens.inline)
                PickerValue(value)
            }
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            // 50 high as drawn; taller at the accessibility sizes.
            .growsWithText()
            .frame(minHeight: Self.height)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

/// The class menu (P4-Attendance-ClassMenu), shown in the system popover: All students and each active class, the
/// count after the name in text3, a tick in accentText on the chosen one; rows 46 high, 260 wide, divided by lineGlass.
struct ClassMenu: View {
    let options: [AttendanceStore.ClassOption]
    let chosen: UUID?
    let choose: (UUID?) -> Void
    static var width: CGFloat {
        260
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(options) { option in
                Button { choose(option.classID) } label: {
                    HStack(spacing: Tokens.fieldGap) {
                        Text(option.name).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                        Text("\(option.count)").typeStyle(Tokens.body).monospacedDigit()
                            .foregroundStyle(Tokens.text3.color)
                        Spacer(minLength: Tokens.inline)
                        if option.classID == chosen {
                            Image(systemName: "checkmark").accessibilityHidden(true)
                                .font(.system(size: Tokens.iconSmall, weight: .semibold))
                                .foregroundStyle(Tokens.accentText.color)
                        }
                    }
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .frame(height: Well<EmptyView>.height)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.name), \(option.count)")
                .accessibilityAddTraits(option.classID == chosen ? .isSelected : [])
                .rowDivider(option.id != options.last?.id, glass: true)
            }
        }
        .frame(width: Self.width)
    }
}

/// "N absent" and a card of the absent students, each with Tell parent or "Told …" (P4-Attendance-Mark-Saved,
/// -PastDate).
struct AbsentSection: View {
    let rows: [AttendanceStore.AbsentRow]
    let tell: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("\(rows.count) absent")
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        AbsentStudentRow(name: row.student.name, line: row.line) {
                            if let told = row.told {
                                ToldMark(told)
                            } else {
                                TellParentButton { tell(row.student.id) }
                            }
                        }
                        .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }
}

/// "6 students" with the counts beside it, then every member's row; the whole row toggles.
struct MembersSection: View {
    let store: AttendanceStore

    var body: some View {
        let members = store.members
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            AdaptiveRow(alignment: .firstTextBaseline, spacing: nil) {
                Text(members.count == 1 ? "1 student" : "\(members.count) students")
                    .typeStyle(Tokens.headline)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                AdaptiveSpacer(minLength: Tokens.inline)
                CountsLine(present: store.draft.presentCount, absent: store.draft.absentCount)
            }
            .padding(.horizontal, Tokens.rowGapInner)
            Card {
                if members.isEmpty {
                    EmptyRow(
                        symbol: "person.2",
                        title: "No students in this batch",
                        line: "Add students to the batch from its page."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(members) { student in
                            AttendanceRow(name: student.name, present: store.draft.marks[student.id] != .absent) {
                                store.toggle(student.id)
                            }
                            .rowDivider(student.id != members.last?.id)
                        }
                    }
                }
            }
        }
    }
}

/// With no students the root is one card (P4-Attendance-Empty): what to do first, and Go to Students.
struct NoStudentsCard: View {
    let openStudents: () -> Void

    var body: some View {
        Card {
            EmptyState(
                symbol: "checkmark.circle",
                title: "No students yet",
                line: "Add your students and their batches first. Marking who came then takes two taps.",
                action: .init("Go to Students", run: openStudents),
                size: .screen
            )
        }
    }
}

/// A read that failed: the line and Retry (Today's pattern).
struct AttendanceErrorLine: View {
    let text: String
    let retry: () -> Void

    init(_ text: String, retry: @escaping () -> Void) {
        self.text = text
        self.retry = retry
    }

    var body: some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry", action: retry).buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}
