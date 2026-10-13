import Foundation

/// A text with formulae in words, for VoiceOver (D102): "x over 4 minus 2 equals 1", "square root of 16", "x squared".
public enum MathSpeech {
    public nonisolated static func words(_ text: String) -> String {
        MathSplit.runs(text).map { run in
            switch run {
            case let .text(words): words
            case let .inline(latex), let .display(latex): spoken(latex)
            }
        }
        .joined()
    }

    private static let symbols: [(String, String)] = [
        ("\\times", " times "), ("\\cdot", " times "), ("\\div", " divided by "), ("\\pm", " plus or minus "),
        ("\\leq", " less than or equal to "), ("\\le", " less than or equal to "),
        ("\\geq", " greater than or equal to "), ("\\ge", " greater than or equal to "), ("\\neq", " not equal to "),
        ("\\pi", " pi "), ("\\theta", " theta "), ("\\alpha", " alpha "), ("\\beta", " beta "), ("\\%", " percent "),
        ("\\degree", " degrees "), ("^\\circ", " degrees "), ("\\left", ""), ("\\right", ""), ("\\,", " "),
        ("−", " minus "), ("=", " equals "), ("+", " plus "), ("-", " minus "), ("<", " less than "),
        (">", " greater than "),
    ]

    /// A formula in words: fractions and roots first (they nest), then powers, then the symbols.
    nonisolated static func spoken(_ latex: String) -> String {
        var said = latex
        said = replacing(command: "\\frac", in: said, arguments: 2) { "\(spoken($0[0])) over \(spoken($0[1]))" }
        said = replacing(command: "\\sqrt", in: said, arguments: 1) { "square root of \(spoken($0[0]))" }
        said = replacing(command: "\\text", in: said, arguments: 1) { $0[0] }
        said = powers(said)
        for (symbol, words) in symbols {
            said = said.replacingOccurrences(of: symbol, with: words)
        }
        said = said.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
        return said.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// `x^{2}` and `x^2` as "x squared", `^3` as "to the 3".
    private nonisolated static func powers(_ text: String) -> String {
        var out = ""
        var chars = Array(text)[...]
        while let first = chars.first {
            chars = chars.dropFirst()
            guard first == "^" else { out.append(first); continue }
            var power = ""
            if chars.first == "{" {
                chars = chars.dropFirst()
                while let c = chars.first, c != "}" {
                    power.append(c); chars = chars.dropFirst()
                }
                chars = chars.dropFirst()
            } else if let c = chars.first {
                power = String(c)
                chars = chars.dropFirst()
            }
            out += power == "2" ? " squared " : power == "3" ? " cubed " : " to the \(spoken(power)) "
        }
        return out.replacingOccurrences(of: " cubed ", with: " to the 3 ")
    }

    /// Each `\command{a}{b}` replaced by `make([a, b])`, braces matched (nesting allowed).
    private nonisolated static func replacing(
        command: String,
        in text: String,
        arguments: Int,
        make: ([String]) -> String
    ) -> String {
        var result = ""
        var rest = Substring(text)
        while let range = rest.range(of: command + "{") {
            result += rest[rest.startIndex ..< range.lowerBound]
            var cursor = rest.index(before: range.upperBound)
            var args: [String] = []
            for _ in 0 ..< arguments {
                guard cursor < rest.endIndex, rest[cursor] == "{",
                      let close = matching(rest, from: cursor) else { break }
                args.append(String(rest[rest.index(after: cursor) ..< close]))
                cursor = rest.index(after: close)
            }
            guard args.count == arguments else {
                result += rest[range]
                rest = rest[range.upperBound...]
                continue
            }
            result += " \(make(args)) "
            rest = rest[cursor...]
        }
        return result + rest
    }

    private nonisolated static func matching(_ text: Substring, from open: Substring.Index) -> Substring.Index? {
        var depth = 0
        var index = open
        while index < text.endIndex {
            if text[index] == "{" {
                depth += 1
            }
            if text[index] == "}" {
                depth -= 1; if depth == 0 {
                    return index
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
}
