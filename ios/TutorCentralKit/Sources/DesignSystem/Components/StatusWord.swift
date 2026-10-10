import SwiftUI

/// A student's tracking status as the Kit draws it (Domain's `TrackStatus`, kept apart: the Kit imports nothing).
public enum TrackKind: Sendable, CaseIterable {
    case notOnTrack, watch, onTrack, notKnown

    /// On track `ok`, Watch `due`, Not on track `overdue`; Not known yet has none (`text3`).
    public var tone: StatusTone? {
        switch self {
        case .onTrack: .ok
        case .watch: .due
        case .notOnTrack: .overdue
        case .notKnown: nil
        }
    }

    public var symbol: String {
        switch self {
        case .onTrack: "checkmark.circle"
        case .watch: "clock"
        case .notOnTrack: "exclamationmark.circle"
        case .notKnown: "circle"
        }
    }

    /// The colour of the word: the tone's, or `text3`.
    public var color: ColorToken {
        tone?.color ?? Tokens.text3
    }
}

/// The status word (components.md "Status word"): footnote 600 in its colour; on a student row it leads the second
/// line.
public struct StatusWord: View {
    let word: String
    let kind: TrackKind

    public init(_ word: String, kind: TrackKind) {
        self.word = word
        self.kind = kind
    }

    public var body: some View {
        Text(word).typeStyle(Tokens.footnoteStrong).foregroundStyle(kind.color.color)
    }
}
