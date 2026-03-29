import Foundation

struct CompleteMelodyGateUseCase: Sendable {
    private let sessionRepository: any SessionRepository

    init(sessionRepository: any SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func execute() async throws -> InterventionSession {
        guard var session = try await sessionRepository.loadCurrentSession() else {
            throw MelotoxError.melodyGateFailed
        }

        session.result = .completed
        session.completedAt = Date()
        try await sessionRepository.saveSession(session)

        return session
    }
}
