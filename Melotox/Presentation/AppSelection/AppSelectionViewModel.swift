import Foundation

struct SelectableApp: Identifiable {
    let id = UUID()
    let token: String
    let name: String
    var isSelected: Bool
}

@MainActor
final class AppSelectionViewModel: ObservableObject {

    // MARK: - Published State

    @Published var availableApps: [SelectableApp] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSave = false

    // MARK: - Dependencies

    private let selectRestrictedAppsUseCase: SelectRestrictedAppsUseCase
    private let restrictionRepository: any RestrictionRepository

    // MARK: - Init

    init(
        selectRestrictedAppsUseCase: SelectRestrictedAppsUseCase,
        restrictionRepository: any RestrictionRepository
    ) {
        self.selectRestrictedAppsUseCase = selectRestrictedAppsUseCase
        self.restrictionRepository = restrictionRepository
    }

    // MARK: - Actions

    func loadApps() {
        Task {
            isLoading = true

            do {
                let profile = try await restrictionRepository.loadProfile()
                let selectedTokens = Set(profile?.selectedApplicationTokens ?? [])

                // In production this would come from ScreenTime FamilyActivitySelection.
                // For now, provide a representative mock list.
                let mockApps = [
                    ("com.instagram", "Instagram"),
                    ("com.twitter", "X (Twitter)"),
                    ("com.tiktok", "TikTok"),
                    ("com.snapchat", "Snapchat"),
                    ("com.youtube", "YouTube"),
                    ("com.reddit", "Reddit"),
                    ("com.facebook", "Facebook"),
                    ("com.pinterest", "Pinterest"),
                ]

                availableApps = mockApps.map { token, name in
                    SelectableApp(
                        token: token,
                        name: name,
                        isSelected: selectedTokens.contains(token)
                    )
                }
            } catch {
                errorMessage = "Failed to load apps."
            }

            isLoading = false
        }
    }

    func toggleApp(token: String) {
        guard let index = availableApps.firstIndex(where: { $0.token == token }) else { return }
        availableApps[index].isSelected.toggle()
    }

    func saveSelection() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let selectedTokens = availableApps
                    .filter(\.isSelected)
                    .map(\.token)

                let existingProfile = try await restrictionRepository.loadProfile()

                let profile = AppRestrictionProfile(
                    id: existingProfile?.id ?? UUID(),
                    selectedApplicationTokens: selectedTokens,
                    isActive: existingProfile?.isActive ?? true
                )

                try await selectRestrictedAppsUseCase.execute(profile: profile)
                didSave = true
            } catch {
                errorMessage = "Failed to save selection."
            }

            isLoading = false
        }
    }
}
