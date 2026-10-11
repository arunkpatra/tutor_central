import DesignSystem
import Domain
import SwiftUI

/// A mark read from the photo (P14-Marks-Edit): the subject as the card prints it, the test, the date (none until set),
/// the score and out of; Remove this mark; Save.
struct ReadMarkEditSheet: View {
    let row: ReadMarksStore.Row
    let subjects: [String]
    let today: Day
    let save: (ReadMark) -> Void
    let remove: () -> Void
    let close: () -> Void
    @State private var subject: String
    @State private var test: String
    @State private var date: Day?
    @State private var score: String
    @State private var max: String
    @State private var pickingDay = false

    init(
        row: ReadMarksStore.Row, subjects: [String], today: Day, save: @escaping (ReadMark) -> Void,
        remove: @escaping () -> Void, close: @escaping () -> Void
    ) {
        self.row = row
        self.subjects = subjects
        self.today = today
        self.save = save
        self.remove = remove
        self.close = close
        _subject = State(initialValue: row.mark.subject)
        _test = State(initialValue: row.mark.test)
        _date = State(initialValue: row.mark.date)
        _score = State(initialValue: "\(row.mark.score)")
        _max = State(initialValue: "\(row.mark.max)")
    }

    /// The mark as edited, when it reads: a test named, a score within out of.
    private var mark: ReadMark? {
        let name = test.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let score = Int(score), let max = Int(max), max > 0, (0 ... max).contains(score)
        else { return nil }
        return ReadMark(subject: subject, test: name, date: date, score: score, max: max)
    }

    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(
                title: "Mark", cancel: ("Cancel", close),
                save: .init("Save", enabled: mark != nil) {
                    if let mark {
                        save(mark)
                    }
                }
            )
        } content: {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    Menu {
                        ForEach(subjects, id: \.self) { name in
                            Button(name) { subject = name }
                        }
                    } label: {
                        PickerTileLabel(label: "Subject", value: subject, placeholder: "")
                    }
                    FieldHelper("As the card prints it. A subject with no book here is kept as written.")
                }
                TextWell(label: "Test", text: $test, capitalisation: .sentences)
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    PickerTile(label: "Date", value: date?.shortText ?? "Choose") { pickingDay = true }
                        .popover(isPresented: $pickingDay) {
                            DatePicker(
                                "Date",
                                selection: dayBinding,
                                in: ...today.date(in: DayHeading.india),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .calendarPopover(timeZone: DayHeading.india.timeZone)
                        }
                    if row.mark.date == nil {
                        FieldHelper("The card gave no date. The mark is saved only once it has one.")
                    }
                }
                HStack(alignment: .top, spacing: Tokens.tileGap) {
                    TextWell(label: "Score", text: $score, numeric: true, keyboard: .numberPad)
                    TextWell(label: "Out of", text: $max, numeric: true, keyboard: .numberPad)
                }
                Button("Remove this mark", action: remove).buttonStyle(.quiet(tone: .overdue))
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { (date ?? today).date(in: DayHeading.india) },
            set: {
                date = Day($0, calendar: DayHeading.india)
                pickingDay = false
            }
        )
    }
}
