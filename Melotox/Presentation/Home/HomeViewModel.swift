import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    @Published var userName: String = ""
    @Published var restrictedAppsCount: Int = 0
    @Published var isRestrictionActive: Bool = false
    @Published var errorMessage: String?

    // MARK: - Navigation

    @Published var shouldNavigateToAppSelection = false

    // MARK: - Dependencies

    private let restrictionRepository: any RestrictionRepository

    // MARK: - Init

    init(restrictionRepository: any RestrictionRepository) {
        self.restrictionRepository = restrictionRepository
    }

    // MARK: - Actions

    func loadProfile(user: User) {
        userName = user.displayName

        Task {
            do {
                if let profile = try await restrictionRepository.loadProfile() {
                    restrictedAppsCount = profile.selectedApplicationTokens.count
                    isRestrictionActive = profile.isActive
                }
            } catch {
                errorMessage = "Failed to load restriction profile."
            }
        }
    }

    func toggleRestriction() {
        Task {
            do {
                guard var profile = try await restrictionRepository.loadProfile() else { return }
                profile.isActive.toggle()
                try await restrictionRepository.saveProfile(profile)
                isRestrictionActive = profile.isActive

                if profile.isActive {
                    try await restrictionRepository.applyRestrictions(
                        for: profile.selectedApplicationTokens
                    )
                } else {
                    try await restrictionRepository.removeRestrictions()
                }
            } catch {
                errorMessage = "Failed to toggle restrictions."
            }
        }
    }

    func navigateToAppSelection() {
        shouldNavigateToAppSelection = true
    }
}
