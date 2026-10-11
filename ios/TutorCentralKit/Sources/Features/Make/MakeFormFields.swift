import DesignSystem
import Domain
import SwiftUI

/// The sheets a form opens over itself.
enum MakeFormSheet: Identifiable, Hashable {
    case forWhom(ForStore.Segment)
    case skill
    case student
    case exam

    var id: Self {
        self
    }
}

/// The kind's tiles (P10-Make-Form; decisions 7 to 11).
extension MakeFormView {
    @ViewBuilder var fields: some View {
        switch form.kind {
        case .sheet:
            forTile
            subjectTile
            skillTile
            ChipRow(
                label: "Length", options: MakeRules.sheetLengths.map { (option: $0.questions, title: $0.title) },
                selection: binding(\.length)
            )
            ChipRow(
                label: "Level", options: MakeRules.levels.map { (option: $0.reason, title: $0.title) },
                selection: binding(\.levelReason)
            )
            SwitchRow(title: "Key at the end", line: MakeWords.keyLine, isOn: binding(\.keyAtEnd))
        case .workedExample:
            forTile
            subjectTile
            skillTile
        case .figure:
            forTile
            subjectTile
            skillTile
            templateTile
        case .brief:
            ClassLevelTile(classLevel: binding(\.classLevel))
            subjectTile
            chapterTile
        case .mock:
            studentTile
            examTile
        case .noteToParent:
            studentTile
            MultilineWell(
                label: "What to say", text: binding(\.tutorSays), placeholder: MakeWords.sayPlaceholder,
                limit: MakeRules.tutorSaysLimit
            )
        case .paper, .homework, .worksheet:
            EmptyView()
        }
    }

    func binding<Value>(_ path: ReferenceWritableKeyPath<MakeFormStore, Value>) -> Binding<Value> {
        let store = form
        return Binding(get: { store[keyPath: path] }, set: { store[keyPath: path] = $0 })
    }

    private func helped(_ helper: String, @ViewBuilder _ tile: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            tile()
            Text(helper)
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
                .padding(.horizontal, Tokens.fieldGap)
        }
    }

    private var forTile: some View {
        helped(MakeWords.forHelper) {
            PickerTile(label: "For", value: form.targetTitle ?? "Choose") { sheet = .forWhom(form.forSegment) }
        }
    }

    @ViewBuilder private var subjectTile: some View {
        let choices = form.subjectChoices
        if choices.isEmpty || typingSubject {
            TextWell(
                label: "Subject",
                text: binding(\.subject),
                placeholder: "Mathematics, Science…",
                capitalisation: .words
            )
        } else {
            Menu {
                ForEach(choices, id: \.self) { subject in
                    Button(subject) { form.subject = subject }
                }
                Button("Type a subject") { typingSubject = true }
            } label: {
                PickerTile(label: "Subject", value: form.subject.isEmpty ? "Choose" : form.subject) {}
            }
        }
    }

    private var skillTile: some View {
        helped(MakeWords.skillHelper) {
            PickerTile(label: "Skill or topic", value: form.skill.isEmpty ? "Type a topic" : form.skill) {
                sheet = .skill
            }
        }
    }

    private var templateTile: some View {
        Menu {
            ForEach(FigureSpec.Kind.allCases, id: \.self) { kind in
                Button(kind.title) { form.chosenTemplate = kind }
            }
        } label: {
            PickerTile(label: "Template", value: form.template?.title ?? "Choose") {}
        }
    }

    @ViewBuilder private var chapterTile: some View {
        let choices = form.chapterChoices
        if choices.isEmpty || typingChapter {
            TextWell(label: "Chapter", text: binding(\.chapter), capitalisation: .sentences)
        } else {
            Menu {
                ForEach(choices, id: \.self) { chapter in
                    Button(chapter) { form.chapter = chapter }
                }
                Button("Type a chapter") { typingChapter = true }
            } label: {
                PickerTile(label: "Chapter", value: form.chapter.isEmpty ? "Choose" : form.chapter) {}
            }
        }
    }

    private var studentTile: some View {
        PickerTile(
            label: "Student",
            value: form.studentID.flatMap { form.context.register.student($0)?.name } ?? "Choose a student"
        ) { sheet = .student }
    }

    @ViewBuilder private var examTile: some View {
        PickerTile(label: "Exam", value: examValue) { sheet = .exam }
            .disabled(form.studentID == nil)
        if case let .typed(subject, title, portions)? = form.exam {
            TextWell(
                label: "Subject",
                text: Binding(
                    get: { subject },
                    set: { form.exam = .typed(subject: $0, title: title, portions: portions) }
                ),
                capitalisation: .words
            )
            TextWell(
                label: "Title",
                text: Binding(
                    get: { title },
                    set: { form.exam = .typed(subject: subject, title: $0, portions: portions) }
                ),
                capitalisation: .sentences
            )
            TextWell(
                label: "Portions",
                text: Binding(
                    get: { portions },
                    set: { form.exam = .typed(subject: subject, title: title, portions: $0) }
                ),
                capitalisation: .sentences
            )
        }
    }

    private var examValue: String {
        switch form.exam {
        case let .item(item)?: "\(item.title) · \(item.date.shortWeekdayText)"
        case .typed?: "Typed"
        case nil: "Choose"
        }
    }

    @ViewBuilder func sheetContent(_ which: MakeFormSheet) -> some View {
        switch which {
        case let .forWhom(segment):
            ForSheet(store: form.forStore(), segment: segment) { target in
                form.choose(target)
                sheet = nil
            } close: { sheet = nil }
        case .skill:
            SkillChooserSheet(choices: form.skillChoices, chosen: form.skill) { skill in
                form.skill = skill
                sheet = nil
            } close: { sheet = nil }
        case .student:
            StudentPickerSheet(
                students: form.context.register.activeStudents, chosen: form.studentID,
                className: { form.context.register.classroom($0)?.name },
                pick: { id in
                    form.studentID = id
                    sheet = nil
                },
                close: { sheet = nil }
            )
        case .exam:
            ExamChooserSheet(exams: form.exams, chosen: form.exam) { exam in
                form.exam = exam
                sheet = nil
            } close: { sheet = nil }
        }
    }
}
