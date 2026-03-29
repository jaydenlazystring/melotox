import Foundation
import Security

// MARK: - KeychainService

/// Lightweight wrapper around the iOS Keychain using kSecClassGenericPassword.
final class KeychainService: Sendable {

    // MARK: - Errors

    enum KeychainError: Error, Sendable {
        case saveFailed(status: OSStatus)
        case loadFailed(status: OSStatus)
        case deleteFailed(status: OSStatus)
        case unexpectedData
    }

    // MARK: - Private

    private let service: String

    // MARK: - Init

    /// - Parameter service: The keychain service name. Defaults to the bundle identifier.
    init(service: String = Bundle.main.bundleIdentifier ?? "com.melotox.app") {
        self.service = service
    }

    // MARK: - Public Methods

    /// Saves data to the keychain for the given key. Overwrites if the key already exists.
    func save(key: String, data: Data) throws {
        // Delete any existing item first to avoid errSecDuplicateItem.
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    /// Loads data from the keychain for the given key. Returns nil if not found.
    func load(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.loadFailed(status: status)
        }
    }

    /// Deletes the keychain item for the given key.
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}
