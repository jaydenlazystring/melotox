import Foundation

// MARK: - UsernameValidation

/// The outcome of validating a candidate handle. `.valid` carries the canonical
/// (lowercased, trimmed) form that should be stored and reserved.
enum UsernameValidation: Equatable, Sendable {
    case valid(canonical: String)
    case tooShort
    case tooLong
    case invalidCharacters
    case edgeUnderscore
    case reserved

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    /// A short, user-facing explanation for invalid states (nil when valid).
    var message: String? {
        switch self {
        case .valid: return nil
        case .tooShort: return "Must be at least \(UsernameValidator.minLength) characters"
        case .tooLong: return "Must be at most \(UsernameValidator.maxLength) characters"
        case .invalidCharacters: return "Use only lowercase letters, numbers, and _"
        case .edgeUnderscore: return "Can't start or end with _"
        case .reserved: return "That username isn't available"
        }
    }
}

// MARK: - UsernameValidator

/// Shared, authoritative username rules used by both the UI (live feedback)
/// and the use cases (final gate). Instagram-style, case-insensitive handles.
enum UsernameValidator {

    static let minLength = 3
    static let maxLength = 20

    /// Handles that must never be claimed by a normal user.
    static let reserved: Set<String> = [
        "admin", "melotox", "support", "root", "about", "help", "settings",
        "profile", "api", "www", "official", "team", "moderator", "mod",
        "null", "undefined", "me", "you", "user",
    ]

    /// Validates a raw candidate and, on success, returns its canonical form.
    static func validate(_ raw: String) -> UsernameValidation {
        let canonical = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard canonical.count >= minLength else { return .tooShort }
        guard canonical.count <= maxLength else { return .tooLong }

        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        guard canonical.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return .invalidCharacters
        }

        if canonical.hasPrefix("_") || canonical.hasSuffix("_") || canonical.contains("__") {
            return .edgeUnderscore
        }

        if reserved.contains(canonical) { return .reserved }

        return .valid(canonical: canonical)
    }
}
