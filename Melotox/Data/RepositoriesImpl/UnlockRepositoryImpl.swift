import Foundation

final class UnlockRepositoryImpl: UnlockRepository {

    private static let grantKeyPrefix = "com.melotox.unlockGrant."

    private let storage: UserDefaultsStorage

    init(storage: UserDefaultsStorage = UserDefaultsStorage()) {
        self.storage = storage
    }

    func grantUnlock(_ grant: UnlockGrant) async throws {
        let dto = UnlockGrantDTO.fromEntity(grant)
        try storage.save(dto, forKey: Self.grantKeyPrefix + grant.appToken)
    }

    func getActiveGrant(for appToken: String) async throws -> UnlockGrant? {
        guard let dto: UnlockGrantDTO = try storage.load(forKey: Self.grantKeyPrefix + appToken) else {
            return nil
        }
        let grant = dto.toEntity()
        if grant.isExpired {
            storage.remove(forKey: Self.grantKeyPrefix + appToken)
            return nil
        }
        return grant
    }

    func expireGrant(id: UUID) async throws {
        // Load all keys with the grant prefix and find the matching grant
        // Since UserDefaults doesn't support querying by value, we search known keys
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix(Self.grantKeyPrefix)
        }
        for key in allKeys {
            if let dto: UnlockGrantDTO = try? storage.load(forKey: key), dto.id == id {
                storage.remove(forKey: key)
                return
            }
        }
    }
}
