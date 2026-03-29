import Foundation

// MARK: - ShieldConfigurationBridge

/// Data describing how a shield overlay should appear.
///
/// Extensions (e.g. ShieldConfiguration extension) can read this from
/// shared App Group UserDefaults to render a consistent blocking screen.
struct ShieldConfigurationBridge: Codable, Sendable {

    // MARK: - Properties

    let title: String
    let subtitle: String
    let primaryButtonLabel: String

    // MARK: - Defaults

    static let `default` = ShieldConfigurationBridge(
        title: "App Blocked",
        subtitle: "Complete your MELOTOX session to unlock this app.",
        primaryButtonLabel: "Open MELOTOX"
    )

    // MARK: - App Group Persistence

    private static let userDefaultsKey = "ShieldConfiguration"

    /// Saves the configuration to the shared App Group suite.
    ///
    /// - Parameter suiteName: The App Group identifier (e.g. "group.com.melotox.shared").
    func save(toAppGroup suiteName: String) throws {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let data = try JSONEncoder().encode(self)
        defaults.set(data, forKey: Self.userDefaultsKey)
    }

    /// Loads a previously saved configuration from the shared App Group suite.
    ///
    /// - Parameter suiteName: The App Group identifier.
    /// - Returns: The decoded configuration, or `nil` if nothing was stored.
    static func load(fromAppGroup suiteName: String) throws -> ShieldConfigurationBridge? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try JSONDecoder().decode(ShieldConfigurationBridge.self, from: data)
    }
}
