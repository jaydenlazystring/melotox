import Foundation

struct ExpireUnlockTimeUseCase: Sendable {
    private let unlockRepository: any UnlockRepository
    private let restrictionRepository: any RestrictionRepository

    init(unlockRepository: any UnlockRepository, restrictionRepository: any RestrictionRepository) {
        self.unlockRepository = unlockRepository
        self.restrictionRepository = restrictionRepository
    }

    func execute(grantId: UUID, tokens: [String]) async throws {
        try await unlockRepository.expireGrant(id: grantId)
        try await restrictionRepository.applyRestrictions(for: tokens)
    }
}
