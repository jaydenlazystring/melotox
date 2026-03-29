import Foundation

// MARK: - NotePattern

/// Describes the timing of notes in a melody-gate sequence.
/// Each entry in `notes` is a `TimeInterval` (seconds from the start)
/// at which a falling note should appear.
struct NotePattern: Codable, Sendable {

    /// Timestamps (in seconds) when each note spawns.
    let notes: [TimeInterval]

    /// Total number of notes in the pattern.
    var count: Int { notes.count }

    // MARK: - Built-in Patterns

    /// A gentle default pattern of 18 notes spread across ~60 seconds.
    /// Average gap is ~3.3 seconds -- meditative, not stressful.
    static func defaultPattern() -> NotePattern {
        NotePattern(notes: [
            2.0,
            5.5,
            9.0,
            12.0,
            15.5,
            18.5,
            22.0,
            25.0,
            28.5,
            31.5,
            35.0,
            38.0,
            41.5,
            44.5,
            48.0,
            51.0,
            54.5,
            58.0
        ])
    }

    // MARK: - JSON Loading

    /// Decodes a `NotePattern` from raw JSON data.
    /// Returns `nil` if the data is malformed.
    static func fromJSON(data: Data) -> NotePattern? {
        try? JSONDecoder().decode(NotePattern.self, from: data)
    }
}
