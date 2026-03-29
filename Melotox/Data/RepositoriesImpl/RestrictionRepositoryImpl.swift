import Foundation

final class RestrictionRepositoryImpl: RestrictionRepository, @unchecked Sendable {

    private static let profileKey = "com.melotox.restrictionProfile"

    private let screenTimeManager: any ScreenTimeManaging
    private let storage: UserDefaultsStorage

    init(screenTimeManager: any ScreenTimeManaging, storage: UserDefaultsStorage = UserDefaultsStorage()) {
        self.screenTimeManager = screenTimeManager
        self.storage = storage
    }

    func saveProfile(_ profile: AppRestrictionProfile) async throws {
        let dto = AppRestrictionProfileDTO.fromEntity(profile)
        try storage.save(dto, forKey: Self.profileKey)
    }

    func loadProfile() async throws -> AppRestrictionProfile? {
        guard let dto: AppRestrictionProfileDTO = try storage.load(forKey: Self.profileKey) else {
            return nil
        }
        return dto.toEntity()
    }

    func applyRestrictions(for tokens: [String]) async throws {
        try await screenTimeManager.applyShield(to: tokens)
    }

    func removeRestrictions() async throws {
        try await screenTimeManager.removeShield()
    }
}
