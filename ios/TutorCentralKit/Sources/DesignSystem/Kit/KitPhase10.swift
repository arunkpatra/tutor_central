#if DEBUG
    import SwiftUI

    /// Phase 10's parts in the Kit (P10-Kit-Dark, -Light; components.md 10.7): tracking status, skill states, item
    /// kinds
    /// and the material's marks, a chapter open with skill rows, the plan line, the check row with the line checklist
    /// and the pair in both states, the ladder and the trend, the figure templates, the board view's type.
    struct KitPhase10: View {
        let figures: (() -> AnyView)?
        @State private var wrong: Bool? = false
        @State private var none: Bool?
        @State private var right: Bool? = true
        @State private var practised = false

        var body: some View {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                KitGroup("Tracking status · chip and word") {
                    FlowLayout(spacing: Tokens.inline) {
                        ForEach(Self.order, id: \.self) { kind in
                            Chip(chipKind(kind), compact: true)
                        }
                    }
                    HStack(spacing: Tokens.tileGap) {
                        ForEach(Self.order, id: \.self) { StatusWord(word($0), kind: $0) }
                    }
                }
                .id(KitView.Section.phase10)
                KitGroup("Skill states") {
                    FlowLayout(spacing: Tokens.tileGap) {
                        ForEach(SkillMark.allCases, id: \.self) { StateMark($0) }
                    }
                }
                KitGroup("School item kinds · the material's marks") {
                    FlowLayout(spacing: Tokens.inline) {
                        ForEach([KindChipKind.exam, .homework, .notice, .holiday], id: \.self) { KindChip($0) }
                    }
                    ReadyMarks([
                        ReadyMark(name: "Set", state: .made), ReadyMark(name: "Sheet", state: .onItsWay),
                        ReadyMark(name: "Checks", state: .notMade),
                    ])
                }
                KitGroup("Chapter row, open, with skill rows") {
                    Card {
                        VStack(spacing: 0) {
                            ChapterRow(
                                position: 3, name: "Quadratic equations", line: "1 secure · 1 revisit · 2 to come",
                                open: true
                            ) {}
                                .rowDivider()
                            SkillRow(name: "Standard form and roots", line: "checked Mon 5 Oct", mark: .secure)
                                .rowDivider()
                            SkillRow(name: "Nature of the roots", line: nil, mark: .revisit)
                        }
                    }
                }
                KitGroup("Plan line") {
                    Card {
                        PlanLineRow(
                            initials: "DK", name: "Dev Kumar", status: ("Not on track", .notOnTrack), note: nil,
                            teachLine: "Teach again: Balancing equations, with the worked example",
                            rest: [
                                LineBit(text: "Practise set 1", struck: false), LineBit(text: "Check 3", struck: false),
                                LineBit(text: "Homework sheet 1", struck: false),
                            ]
                        ) {}
                    }
                }
                KitGroup("Check row · line checklist · right or wrong") {
                    Card {
                        VStack(spacing: 0) {
                            CheckRow(
                                skill: "Comparing fractions", question: "Which is bigger, 3/4 or 2/3?", answer: "3/4",
                                tap: $wrong
                            )
                            .rowDivider()
                            PlanChecklistRow(isOn: $practised, text: "Practise set 1")
                        }
                    }
                    HStack(spacing: Tokens.tileGap) {
                        RightWrongPair(tap: $none, about: "untapped")
                        RightWrongPair(tap: $right, about: "right")
                    }
                }
                KitGroup("Ladder · check trend") {
                    Card {
                        LadderRow(title: "Reading", line: "Words", steps: [
                            ("Letters", .secure), ("Words", .current), ("Sentences", .later), ("Paragraph", .later),
                            ("Story", .later),
                        ])
                    }
                    TrendCard(
                        title: "Three weeks", percent: "50%", right: [3, 2, 1, 3, 2, 1, 1, 2, 0, 1, 2, 1],
                        line: "9 of 18 right · 3 questions a class"
                    )
                }
                if let figures {
                    KitGroup("Figure templates · the validators' previews") { figures() }
                        .id(KitView.Section.phase10Figures)
                }
                KitGroup("Board view type · 44/52 700") {
                    Card {
                        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                            Eyebrow("Balance the equation")
                            Text("Na + Cl₂ → NaCl").typeStyle(Tokens.displayHero).foregroundStyle(Tokens.text.color)
                            Text("Question 3").typeStyle(Tokens.title2).foregroundStyle(Tokens.text2.color)
                        }
                    }
                }
            }
        }

        /// The board's order.
        private static let order: [TrackKind] = [.onTrack, .watch, .notOnTrack, .notKnown]

        private func word(_ kind: TrackKind) -> String {
            switch kind {
            case .onTrack: "On track"
            case .watch: "Watch"
            case .notOnTrack: "Not on track"
            case .notKnown: "Not known yet"
            }
        }

        private func chipKind(_ kind: TrackKind) -> Chip.Kind {
            guard let tone = kind.tone else { return .neutral(word(kind), symbol: kind.symbol) }
            return .status(tone, word(kind), symbol: kind.symbol)
        }
    }
#endif
