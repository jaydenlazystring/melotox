import Foundation

final class SessionRepositoryImpl: SessionRepository {

    private static let sessionKey = "com.melotox.currentSession"
    private static let activityKey = "com.melotox.activityHistory"

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

    func recordActivity(_ record: ActivityRecord) async throws {
        var history = (try? await loadActivityHistory()) ?? []
        history.append(record)
        try storage.save(history, forKey: Self.activityKey)
    }

    func loadActivityHistory() async throws -> [ActivityRecord] {
        let records: [ActivityRecord]? = try storage.load(forKey: Self.activityKey)
        return records ?? []
    }
}
