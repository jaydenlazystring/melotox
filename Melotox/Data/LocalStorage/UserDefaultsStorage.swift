import Foundation

final class UserDefaultsStorage: @unchecked Sendable {

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Codable & Sendable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        defaults.set(data, forKey: key)
    }

    func load<T: Codable & Sendable>(forKey key: String, as type: T.Type = T.self) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
