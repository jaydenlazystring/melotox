import Foundation

final class SessionRepositoryImpl: SessionRepository {

    private static let sessionKey = "com.melotox.currentSession"

    private let storage: UserDefaultsStorage

    init(storage: UserDefaultsStorage = UserDefaultsStorage()) {
        self.storage = storage
    }

    func saveSession(_ session: InterventionSession) async throws {
        let dto = InterventionSessionDTO.fromEntity(session)
        try storage.save(dto, forKey: Self.sessionKey)
    }

    func loadCurrentSession() async throws -> InterventionSession? {
        guard let dto: InterventionSessionDTO = try storage.load(forKey: Self.sessionKey) else {
            return nil
        }
        return dto.toEntity()
    }

    func clearCurrentSession() async throws {
        storage.remove(forKey: Self.sessionKey)
    }
}
