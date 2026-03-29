import Foundation

// MARK: - ScreenTimeManaging

/// Abstraction over Apple's Screen Time / Family Controls APIs.
protocol ScreenTimeManaging: Sendable {

    /// Requests authorization to use Screen Time features.
    func requestAuthorization() async throws

    /// Presents the app-picker UI and returns opaque application tokens.
    func selectApps() async throws -> [String]

    /// Applies a shield (blocking overlay) to the given application tokens.
    func applyShield(to tokens: [String]) async throws

    /// Removes any active shield.
    func removeShield() async throws

    /// Whether the user has granted Screen Time authorization.
    var isAuthorized: Bool { get }
}

// MARK: - ScreenTimeError

enum ScreenTimeError: Error, Sendable {
    case screenTimeNotAuthorized
    case authorizationDenied
    case selectionCancelled
    case shieldApplicationFailed(underlying: String)
}
