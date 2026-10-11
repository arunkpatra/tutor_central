import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the AI Assistant's screens: Create already tapped (P6-Generating, -Generate-Failed),
/// Create again tapped (P6-Result-Regenerating), the student picker or the Send sheet open.
public enum AIBoardState: Hashable, Sendable {
    case generating, failed, regenerating, noteSend, studentPicker
    /// The Class tile open on the class wheel (P12-Form-Paper-ClassWheel).
    case classWheel
    /// The result with Copy in its done state (U33-Result-Copied).
    case copied
    /// The centre's consent sheet over the note's form (P15-Consent-Note, U20).
    case consent
}

/// A form (P6-Form-Paper, -Homework, -Worksheet, -ProgressNote), pushed: one card of fields, a footnote, and Create in
/// the footer. Creating holds the form under the creating card; a failure shows the error row with Retry. The call is
/// the store's: leaving the screen does not lose it, and AppShell pushes the result when it lands.
public struct GenerateFormView: View {
    let store: AIStore
    let kind: GenerationKind
    let boardState: AIBoardState?
    let showsFocus: Bool
    @State private var paper: PaperForm
    @State private var homework: HomeworkForm
    @State private var worksheet: WorksheetForm
    @State private var note: NoteForm
    @State private var pickingStudent = false
    @State private var consent = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: AIStore, kind: GenerationKind, boardState: AIBoardState? = nil, showsFocus: Bool = false) {
        self.store = store
        self.kind = kind
        self.boardState = boardState
        self.showsFocus = showsFocus
        let draft = store.form(for: kind)
        _paper = State(initialValue: Self.paper(draft))
        _homework = State(initialValue: Self.homework(draft))
        _worksheet = State(initialValue: Self.worksheet(draft))
        _note = State(initialValue: Self.note(draft))
        _pickingStudent = State(initialValue: boardState == .studentPicker)
        _consent = State(initialValue: boardState == .consent)
    }

    private static func paper(_ draft: GenerateRequest) -> PaperForm {
        guard case let .paper(form) = draft else { return PaperForm() }
        return form
    }

    private static func homework(_ draft: GenerateRequest) -> HomeworkForm {
        guard case let .homework(form) = draft else { return HomeworkForm() }
        return form
    }

    private static func worksheet(_ draft: GenerateRequest) -> WorksheetForm {
        guard case let .worksheet(form) = draft else { return WorksheetForm() }
        return form
    }

    private static func note(_ draft: GenerateRequest) -> NoteForm {
        guard case let .progressNote(form) = draft else { return NoteForm() }
        return form
    }

    private var request: GenerateRequest {
        switch kind {
        case .paper: .paper(paper)
        case .homework: .homework(homework)
        case .worksheet: .worksheet(worksheet)
        case .progressNote: .progressNote(note)
        }
    }

    private var creating: Bool {
        store.inFlight?.kind == kind && store.inFlight?.regenerating == nil
    }

    private var student: Student? {
        note.studentID.flatMap(store.register.student)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: kind.title) { dismiss() }
                Card(.hero) {
                    VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) { fields }
                }
                .opacity(creating ? Tokens.opacityDisabled : 1)
                .allowsHitTesting(!creating)
                below
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .onChange(of: request) { _, now in store.forms[kind] = now }
        .onChange(of: store.failure) { _, failure in
            if failure?.kind == kind, failure?.consent == true {
                consent = true
            }
        }
        .task {
            await store.prepare()
            fillLevelIfNone()
        }
        .task(id: note.studentID) {
            await store.prepare()
            if let id = note.studentID {
                await store.loadMonthLine(for: id)
            }
        }
        .onAppear {
            if boardState == .generating || boardState == .failed {
                create()
            }
        }
        .sheet(isPresented: $pickingStudent) {
            StudentPickerSheet(
                students: store.register.activeStudents, chosen: note.studentID, className: store.className
            ) { id in
                note.studentID = id
                pickingStudent = false
            } close: {
                pickingStudent = false
            }
        }
        .sheet(isPresented: $consent) {
            ConsentSheet(kind: kind == .progressNote ? .note : .photo, centreName: store.workspace.centre.name) {
                let agreed = await store.recordConsent()
                if agreed {
                    consent = false
                    create()
                }
                return agreed
            } close: {
                consent = false
            }
        }
    }

    @ViewBuilder private var fields: some View {
        switch kind {
        case .paper:
            classFields(
                classLevel: $paper.classLevel,
                subject: $paper.subject,
                topic: $paper.topic,
                level: $paper.level
            )
            NumberTile(label: "Questions", value: $paper.questions, range: PaperForm.questionsRange)
            NumberTile(label: "Marks", value: $paper.marks, range: PaperForm.marksRange)
        case .homework:
            classFields(
                classLevel: $homework.classLevel, subject: $homework.subject, topic: $homework.topic,
                level: $homework.level
            )
            NumberTile(label: "Questions", value: $homework.questions, range: HomeworkForm.questionsRange)
        case .worksheet:
            classFields(
                classLevel: $worksheet.classLevel, subject: $worksheet.subject, topic: $worksheet.topic,
                level: $worksheet.level
            )
            NumberTile(label: "Questions", value: $worksheet.questions, range: WorksheetForm.questionsRange)
            SwitchRow(
                title: "Answer key at the end", line: "The answers on their own page, for you.",
                isOn: $worksheet.withAnswers
            )
        case .progressNote:
            noteFields
        }
    }

    @ViewBuilder
    private func classFields(
        classLevel: Binding<ClassLevel?>, subject: Binding<String>, topic: Binding<String>, level: Binding<Level>
    ) -> some View {
        ClassLevelTile(classLevel: classLevel, opensWheel: boardState == .classWheel)
        TextWell(label: "Subject", text: subject, placeholder: "Mathematics, Science…", capitalisation: .words)
        TextWell(
            label: "Topic", text: topic, capitalisation: .sentences, showsFocus: showsFocus,
            autofocus: !showsFocus && topic.wrappedValue.isEmpty
        )
        Labelled(label: "Level") {
            Segmented(options: Level.allCases.map { ($0, $0.title) }, selection: level)
        }
    }

    @ViewBuilder private var noteFields: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            PickerTile(label: "Student", value: student?.name ?? "Choose a student") { pickingStudent = true }
            if let student {
                Text(studentLine(student))
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text2.color)
                    .padding(.horizontal, Tokens.fieldGap)
            }
        }
        if let id = note.studentID, let line = store.monthLines[id] {
            Banner(symbol: "info.circle", text: "This month: \(line)")
        }
        MultilineWell(
            label: "What you have seen", text: $note.observations, placeholder: "",
            limit: NoteForm.observationsLimit, showsFocus: showsFocus, slashed: true
        )
        Labelled(label: "Tone") {
            Segmented(options: Tone.allCases.map { ($0, $0.title) }, selection: $note.tone)
        }
    }

    @ViewBuilder private var below: some View {
        if creating, let inFlight = store.inFlight {
            CreatingCard(title: inFlight.line, line: AIWords.creatingLine) { store.cancel() }
        } else if let failure = store.failure, failure.kind == kind, !failure.consent {
            ErrorRow(
                title: AIWords.failedTitle(kind), line: AIWords.failedLine(failure.message),
                retry: failure.canRetry ? { store.retry() } : nil
            )
        } else {
            Text(AIWords.footnote(kind, parentName: student?.parentName))
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }

    private var footer: some View {
        FooterButton {
            Button {
                create()
            } label: {
                Label(kind.createLabel, systemImage: "sparkles")
            }
            .buttonStyle(.primary(.card, loading: creating))
            .disabled(!request.isValid)
        }
    }

    private func studentLine(_ student: Student) -> String {
        // A number never breaks across lines.
        let phone = student.parentPhone?.display.replacingOccurrences(of: " ", with: "\u{00A0}")
        let parent = [student.parentName, phone].compactMap(\.self).joined(separator: ", ")
        return [store.className(student.classID), parent.isEmpty ? nil : parent].compactMap(\.self)
            .joined(separator: " · ")
    }

    /// A new form opened before the register was read: the first active class and its subject, once it is.
    /// A form made before the register was read starts on its class now (the last chosen, else the class most
    /// students are in); a class already chosen stays.
    private func fillLevelIfNone() {
        guard let level = store.startingLevel(for: kind) else { return }
        switch kind {
        case .paper where paper.classLevel == nil: paper.classLevel = level
        case .homework where homework.classLevel == nil: homework.classLevel = level
        case .worksheet where worksheet.classLevel == nil: worksheet.classLevel = level
        default: break
        }
    }

    private func create() {
        guard !creating else { return }
        Keyboard.dismiss()
        if store.create(request) == .needsConsent {
            consent = true
        }
    }
}
