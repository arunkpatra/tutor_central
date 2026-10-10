import SwiftUI

/// The board view (P10-Sheet-Board): `ground` full screen, one question at a time in the hero's size, for a class to
/// read off the phone held up or cast. The top row (quiet Done, "3 of 8", quiet Key), the eyebrow, the question,
/// "Question
/// n", the answer under it in `ok` 600 when the key shows, then Previous and Next of equal widths.
public struct BoardView: View {
    let eyebrow: String?
    let question: String
    let number: Int
    let count: Int
    let answer: String?
    let showsKey: Bool
    let previous: () -> Void
    let next: () -> Void
    let done: () -> Void
    let toggleKey: () -> Void

    public init(
        eyebrow: String?, question: String, number: Int, count: Int, answer: String?, showsKey: Bool,
        previous: @escaping () -> Void, next: @escaping () -> Void, done: @escaping () -> Void,
        toggleKey: @escaping () -> Void
    ) {
        self.eyebrow = eyebrow
        self.question = question
        self.number = number
        self.count = count
        self.answer = answer
        self.showsKey = showsKey
        self.previous = previous
        self.next = next
        self.done = done
        self.toggleKey = toggleKey
    }

    /// "3 of 8".
    public nonisolated static func countText(number: Int, of count: Int) -> String {
        "\(number) of \(count)"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("Done", action: done).buttonStyle(.quiet(emphasised: true))
                Spacer()
                Text(Self.countText(number: number, of: count))
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                Spacer()
                Button(showsKey ? "Hide key" : "Key", action: toggleKey).buttonStyle(.quiet(emphasised: true))
            }
            Spacer()
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                if let eyebrow {
                    Eyebrow(eyebrow)
                }
                Text(question)
                    .typeStyle(Tokens.displayHero)
                    .foregroundStyle(Tokens.text.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(SingleLineTitle.smallest)
                Text("Question \(number)").typeStyle(Tokens.title2).foregroundStyle(Tokens.text2.color)
                if showsKey, let answer {
                    Text(answer).typeStyle(Tokens.title3).foregroundStyle(Tokens.ok.color)
                }
            }
            Spacer()
            HStack(spacing: Tokens.tileGap) {
                Button(action: previous) { Label("Previous", systemImage: "chevron.left").frame(maxWidth: .infinity) }
                    .buttonStyle(.secondary(.sheet))
                    .disabled(number <= 1)
                Button(action: next) { Label("Next", systemImage: "arrow.right").frame(maxWidth: .infinity) }
                    .buttonStyle(.primary(.sheet))
                    .disabled(number >= count)
            }
        }
        .padding(.horizontal, Tokens.pageSide)
        .padding(.vertical, Tokens.pageTop)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Tokens.ground.color)
    }
}

/// A key row (P10-Sheet-Key): the question row with its answer under it in `rowLine` `ok` 600.
public struct KeyRow: View {
    let number: Int
    let question: String
    let answer: String
    let isLast: Bool

    public init(number: Int, question: String, answer: String, isLast: Bool) {
        self.number = number
        self.question = question
        self.answer = answer
        self.isLast = isLast
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.tileGap) {
            Text("\(number).")
                .typeStyle(Tokens.buttonSecondary).monospacedDigit().foregroundStyle(Tokens.text2.color)
                .frame(minWidth: QuestionRow.numberColumn, alignment: .leading)
                .fixedSize()
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(question).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color)
                    .fixedSize(horizontal: false, vertical: true)
                Text(answer).typeStyle(Tokens.rowLine).fontWeight(.semibold).foregroundStyle(Tokens.ok.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .rowDivider(!isLast)
        .accessibilityElement(children: .combine)
    }
}

/// A step (P10-WorkedExample, the brief's mistakes): a 28 pt disc with the number (`accentTint` and `accentText` when
/// shown; `surface2` and `text2` to come, the row at 0.45 with its title only), the title `rowTitle`, the working
/// `subhead` `text2`.
public struct StepRow: View {
    let number: Int
    let title: String
    let working: String?
    let shown: Bool
    static var disc: CGFloat {
        28
    }

    static var dimmed: Double {
        0.45
    }

    public init(number: Int, title: String, working: String?, shown: Bool) {
        self.number = number
        self.title = title
        self.working = working
        self.shown = shown
    }

    /// A step to come shows its title only.
    public nonisolated static func showsWorking(shown: Bool, working: String?) -> Bool {
        shown && working != nil
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
            Text("\(number)")
                .typeStyle(Tokens.footnoteStrong)
                .foregroundStyle((shown ? Tokens.accentText : Tokens.text2).color)
                .frame(width: Self.disc, height: Self.disc)
                .background((shown ? Tokens.accentTint : Tokens.surface2).color, in: .circle)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    .fixedSize(horizontal: false, vertical: true)
                if Self.showsWorking(shown: shown, working: working), let working {
                    Text(working).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .opacity(shown ? 1 : Self.dimmed)
        .accessibilityElement(children: .combine)
    }
}

/// The tutor's own sheet as its photo (P10-Sheet-Own): `surface2`, the raised shadow, radius 18, as tall as the photo's
/// aspect allows.
public struct PhotoCard: View {
    let image: UIImage

    public init(image: UIImage) {
        self.image = image
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .background(Tokens.surface2.color)
            .clipShape(.rect(cornerRadius: Tokens.radiusCard, style: .continuous))
            .shadowed(Tokens.shadowRaised, radius: Tokens.radiusCard)
            .accessibilityLabel("Your sheet")
    }
}

/// A figure in its card (P10-Figure-*): a list card (padding 16) holding the figure on `surface2` (radius 12, padding
/// 12, centred) and the caption `footnote` `text2` centred.
public struct FigureCard<Figure: View>: View {
    let caption: String
    let figure: Figure
    static var inner: CGFloat {
        12
    }

    public init(caption: String, @ViewBuilder figure: () -> Figure) {
        self.caption = caption
        self.figure = figure()
    }

    public var body: some View {
        Card {
            VStack(spacing: Tokens.tileGap) {
                figure
                    .padding(Self.inner)
                    .frame(maxWidth: .infinity)
                    .background(Tokens.surface2.color, in: .rect(cornerRadius: Self.inner, style: .continuous))
                Text(caption)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text2.color)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(Tokens.rowPaddingHorizontal)
        }
    }
}
