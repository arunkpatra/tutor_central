import Foundation

/// A piece of a text: words, an inline formula or a display formula (LaTeX maths mode, D102).
public enum MathRun: Equatable, Sendable {
    case text(String)
    case inline(String)
    case display(String)
}

/// A text split into words and formulae (D102): `$$…$$` a display formula, `$…$` an inline one, `\$` a dollar; a `$`
/// with no partner is a word, so a slip never hides a question; a `\text{…}` holding letters outside ASCII is lifted
/// out as words (XITS Math has no Devanagari or Kannada). The server's PDF splits by the same rules
/// (`api/src/pdf/maths.ts`), held equal by `tools/contract/maths-cases.json`.
public enum MathSplit {
    public nonisolated static func hasMaths(_ text: String) -> Bool {
        runs(text).contains {
            if case .text = $0 {
                false
            } else {
                true
            }
        }
    }

    public nonisolated static func runs(_ source: String) -> [MathRun] {
        var runs: [MathRun] = []
        func word(_ text: String) {
            guard !text.isEmpty else { return }
            if case let .text(last) = runs.last {
                runs[runs.count - 1] = .text(last + text)
            } else {
                runs.append(.text(text))
            }
        }
        func formula(_ display: Bool, _ latex: String) {
            for part in liftWords(latex) {
                switch part {
                case let .text(words): word(words)
                case let .inline(maths) where !maths.trimmingCharacters(in: .whitespaces).isEmpty:
                    runs.append(display ? .display(maths) : .inline(maths))
                default: break
                }
            }
        }
        let chars = Array(source)
        var index = 0
        var pending = ""
        while index < chars.count {
            if chars[index] == "\\", index + 1 < chars.count, chars[index + 1] == "$" {
                pending.append("$")
                index += 2
                continue
            }
            guard chars[index] == "$" else {
                pending.append(chars[index])
                index += 1
                continue
            }
            let display = index + 1 < chars.count && chars[index + 1] == "$"
            let open = display ? 2 : 1
            let close = display ? doubleDollar(chars, from: index + 2) : nextDollar(chars, from: index + 1)
            let latex = close.map { String(chars[(index + open) ..< $0]) } ?? ""
            guard let end = close, !latex.trimmingCharacters(in: .whitespaces).isEmpty else {
                // No partner, or nothing between: the rest is words as written.
                pending.append(String(chars[index...]))
                break
            }
            word(pending)
            pending = ""
            formula(display, latex)
            index = end + open
        }
        word(pending)
        return runs
    }

    private nonisolated static func nextDollar(_ chars: [Character], from start: Int) -> Int? {
        var index = start
        while index < chars.count {
            if chars[index] == "\\" {
                index += 2; continue
            }
            if chars[index] == "$" {
                return index
            }
            index += 1
        }
        return nil
    }

    private nonisolated static func doubleDollar(_ chars: [Character], from start: Int) -> Int? {
        var index = start
        while index + 1 < chars.count {
            if chars[index] == "$", chars[index + 1] == "$" {
                return index
            }
            index += 1
        }
        return nil
    }

    /// A formula's `\text{…}` runs whose letters are outside ASCII, lifted out as words; the rest stays maths.
    private nonisolated static func liftWords(_ latex: String) -> [MathRun] {
        var parts: [MathRun] = []
        var rest = Substring(latex)
        var maths = ""
        while let range = rest.range(of: "\\text{") {
            guard let close = rest[range.upperBound...].firstIndex(of: "}") else { break }
            let inner = String(rest[range.upperBound ..< close])
            maths += rest[rest.startIndex ..< range.lowerBound]
            if inner.unicodeScalars.allSatisfy(\.isASCII) || inner.contains("{") {
                maths += rest[range.lowerBound ... close]
            } else {
                parts.append(.inline(maths))
                parts.append(.text(inner))
                maths = ""
            }
            rest = rest[rest.index(after: close)...]
        }
        parts.append(.inline(maths + rest))
        return parts
    }
}
