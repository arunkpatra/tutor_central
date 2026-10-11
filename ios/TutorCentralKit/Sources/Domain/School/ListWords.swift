/// A list in words: "a", "a and b", "a, b and c".
enum ListWords {
    static func and(_ words: [String]) -> String {
        guard let last = words.last, words.count > 1 else { return words.first ?? "" }
        return "\(words.dropLast().joined(separator: ", ")) and \(last)"
    }
}
