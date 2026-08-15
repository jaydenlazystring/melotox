import Foundation

struct User: Identifiable, Codable, Sendable, Equatable {
    /// Stable identity. When Firebase Auth is configured this is the Firebase `uid`;
    /// otherwise a locally generated identifier.
    let id: String
    let provider: AuthProvider
    let email: String
    let displayName: String
    /// The user's chosen public handle (without the leading "@"). `nil` until picked.
    var username: String?
    let createdAt: Date
}
