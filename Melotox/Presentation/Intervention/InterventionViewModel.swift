import Foundation

@MainActor
final class InterventionViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentSession: InterventionSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowMelodyGate = false
    @Published var shouldDismiss = false

    // MARK: - Dependencies

    private let startInterventionUseCase: StartInterventionUseCase

    // MARK: - Context

    private var appToken: String = ""

    // MARK: - Init

    init(startInterventionUseCase: StartInterventionUseCase) {
        self.startInterventionUseCase = startInterventionUseCase
    }

    // MARK: - Actions

    func startIntervention(for appToken: String) {
        self.appToken = appToken
    }

    func submitAnswer(_ answer: QuestionAnswer) {
        switch answer {
        case .no:
            shouldDismiss = true

        case .yes:
            Task {
                isLoading = true
                errorMessage = nil

                do {
                    let session = try await startInterventionUseCase.execute(
                        appToken: appToken,
                        answer: .yes
                    )
                    currentSession = session
                    shouldShowMelodyGate = true
                } catch {
                    errorMessage = "Failed to start session. Please try again."
                }

                isLoading = false
            }
        }
    }
}
