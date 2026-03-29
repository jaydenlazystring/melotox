import Foundation

struct GrantUnlockTimeUseCase: Sendable {
    private let unlockRepository: any UnlockRepository
    private let restrictionRepository: any RestrictionRepository

    init(unlockRepository: any UnlockRepository, restrictionRepository: any RestrictionRepository) {
        self.unlockRepository = unlockRepository
        self.restrictionRepository = restrictionRepository
    }

    func execute(appToken: String, minutes: Int) async throws -> UnlockGrant {
        let now = Date()
        let grant = UnlockGrant(
            id: UUID(),
            appToken: appToken,
            grantedMinutes: minutes,
            startAt: now,
            endAt: now.addingTimeInterval(TimeInterval(minutes * 60))
        )

        try await unlockRepository.grantUnlock(grant)
        try await restrictionRepository.removeRestrictions()

        return grant
    }
}
