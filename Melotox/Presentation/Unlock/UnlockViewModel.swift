import Foundation

@MainActor
final class UnlockViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedDuration: Int?
    @Published var isGranted = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let grantUnlockTimeUseCase: GrantUnlockTimeUseCase

    // MARK: - Context

    private let appToken: String

    // MARK: - Init

    init(appToken: String, grantUnlockTimeUseCase: GrantUnlockTimeUseCase) {
        self.appToken = appToken
        self.grantUnlockTimeUseCase = grantUnlockTimeUseCase
    }

    // MARK: - Actions

    func selectDuration(_ minutes: Int) {
        selectedDuration = minutes

        Task {
            isLoading = true
            errorMessage = nil

            do {
                _ = try await grantUnlockTimeUseCase.execute(
                    appToken: appToken,
                    minutes: minutes
                )
                isGranted = true
            } catch {
                errorMessage = "Failed to grant unlock. Please try again."
                selectedDuration = nil
            }

            isLoading = false
        }
    }
}
