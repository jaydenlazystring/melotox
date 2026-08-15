import Foundation

// MARK: - UserProfileError

enum UserProfileError: Error, Sendable {
    /// The requested handle was already taken (surfaced by the atomic reservation).
    case usernameTaken
    case notAuthenticated
    case backendUnavailable
}

// MARK: - UserProfileRepository

/// The source-of-truth store for user records and username uniqueness.
/// Backed by Firestore when configured, or a local fallback otherwise.
protocol UserProfileRepository: Sendable {
    /// Returns the stored profile for the given uid, or nil if none exists yet.
    func fetchProfile(uid: String) async throws -> User?

    /// Creates or updates the base user record (does not touch the username).
    func upsertUser(_ user: User) async throws

    /// Advisory availability check (UX only). The real guard is `setUsername`.
    func isUsernameAvailable(_ canonical: String) async throws -> Bool

    /// Atomically reserves `canonical` for `uid` and returns the updated user.
    /// Throws `UserProfileError.usernameTaken` if it was claimed concurrently.
    func setUsername(_ canonical: String, for uid: String) async throws -> User
}
