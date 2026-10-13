#if DEBUG
    import SwiftUI

    /// Phase 20's mathematics in the Kit (P20-Kit-Maths, -Light; components.md "Phase 20 parts"): formulae in the
    /// paper's
    /// rows and a key, a display formula, the board view's type with maths, Hindi and Kannada beside a formula, maths
    /// that could not be read, and the footnote naming the faces.
    struct KitPhase20: View {
        var body: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                KitGroup("Mathematics in a row · 15/22, the maths face beside SF Pro") {
                    Card {
                        VStack(spacing: 0) {
                            QuestionRow(number: 1, text: "Solve $3x + 5 = 20$.", marks: "1", isLast: false)
                            QuestionRow(
                                number: 2,
                                text: "Simplify $\\frac{2^3 \\times 2^4}{2^5}$.",
                                marks: "1",
                                isLast: false
                            )
                            KeyRow(
                                number: 3,
                                question: "Find $x$ if $\\frac{2x + 1}{3} = 5$.",
                                answer: "$x = 7$",
                                isLast: true
                            )
                        }
                    }
                }
                .id(KitView.Section.phase20)
                KitGroup("Display formula · centred, 1.25×") {
                    Card {
                        MathText(
                            "Use the formula $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$ and then check both roots."
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Tokens.rowPaddingDense)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    }
                }
                KitGroup("Board view type · 44/52 700 with maths") {
                    Card {
                        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                            Eyebrow("Solve for x")
                            MathText("$\\frac{x}{4} - 2 = 1$", style: Tokens.displayHero)
                            Text("Question 2").typeStyle(Tokens.title2).foregroundStyle(Tokens.text2.color)
                            MathText("$x = 12$", style: Tokens.title3, color: Tokens.ok)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Tokens.rowPaddingHorizontal)
                    }
                }
                KitGroup("Hindi and Kannada beside a formula · words outside, symbols inside") {
                    Card {
                        VStack(spacing: 0) {
                            QuestionRow(
                                number: 1,
                                text: "आधा लिखिए: $\\frac{1}{2}$। एक चौथाई: $\\frac{1}{4}$।",
                                marks: "1",
                                isLast: false
                            )
                            QuestionRow(
                                number: 2,
                                text: "ಅರ್ಧ: $\\frac{1}{2}$. ಕಾಲು ಭಾಗ: $\\frac{1}{4}$.",
                                marks: "1",
                                isLast: false
                            )
                            QuestionRow(
                                number: 3,
                                text: "$3 \\text{ सेब} + 2 \\text{ सेब} = 5 \\text{ सेब}$",
                                marks: "1",
                                isLast: true
                            )
                        }
                    }
                }
                KitGroup("Maths that could not be read · shown as written, nothing hidden") {
                    Card {
                        QuestionRow(number: 4, text: "Solve $\\frac{x}{4 - 2 = 1$", marks: "1", isLast: true)
                    }
                    KitNote(Self.footnote)
                }
            }
        }

        static let footnote = "The maths face: XITS Math on the iPhone (SwiftMath), STIX Two Math in the PDF "
            + "(Typst with mitex), the same family. Letters italic, numbers upright, fractions stacked, roots with "
            + "their bar. Dynamic Type scales a formula with the words around it."
    }
#endif
