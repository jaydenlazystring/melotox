import Foundation

// MARK: - SessionStorage

/// Stores and retrieves the current user session (serialized User entity)
/// in the iOS Keychain via `KeychainService`.
final class SessionStorage: Sendable {

    // MARK: - Constants

    private static let sessionKey = "com.melotox.userSession"

    // MARK: - Dependencies

    private let keychain: KeychainService

    // MARK: - Init

    /// - Parameter keychain: The keychain service to use for persistence.
    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    // MARK: - Public Methods

    /// Saves the JSON-encoded user data to the keychain.
    func saveUser(_ user: Data) throws {
        try keychain.save(key: Self.sessionKey, data: user)
    }

    /// Loads the JSON-encoded user data from the keychain, if present.
    func loadUser() throws -> Data? {
        try keychain.load(key: Self.sessionKey)
    }

    /// Removes the stored user session from the keychain.
    func clearUser() throws {
        try keychain.delete(key: Self.sessionKey)
    }
}
