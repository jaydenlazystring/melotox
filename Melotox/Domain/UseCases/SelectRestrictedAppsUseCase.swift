import Foundation

struct SelectRestrictedAppsUseCase: Sendable {
    private let restrictionRepository: any RestrictionRepository

    init(restrictionRepository: any RestrictionRepository) {
        self.restrictionRepository = restrictionRepository
    }

    func execute(profile: AppRestrictionProfile) async throws {
        try await restrictionRepository.saveProfile(profile)
    }
}
