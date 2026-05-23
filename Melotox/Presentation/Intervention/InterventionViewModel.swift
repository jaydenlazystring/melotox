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
    private let sessionRepository: any SessionRepository

    // MARK: - Context

    private var appToken: String = ""

    // MARK: - Init

    init(startInterventionUseCase: StartInterventionUseCase,
         sessionRepository: any SessionRepository) {
        self.startInterventionUseCase = startInterventionUseCase
        self.sessionRepository = sessionRepository
    }

    // MARK: - Actions

    func startIntervention(for appToken: String) {
        self.appToken = appToken
    }

    func submitAnswer(_ answer: QuestionAnswer) {
        switch answer {
        case .no:
            Task {
                let record = ActivityRecord(date: Date(), type: .declined)
                try? await sessionRepository.recordActivity(record)
            }
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
