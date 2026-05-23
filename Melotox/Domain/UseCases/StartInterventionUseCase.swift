import Foundation

struct StartInterventionUseCase: Sendable {
    private let sessionRepository: any SessionRepository
    private let audioRepository: any AudioRepository

    init(sessionRepository: any SessionRepository, audioRepository: any AudioRepository) {
        self.sessionRepository = sessionRepository
        self.audioRepository = audioRepository
    }

    func execute(appToken: String, answer: QuestionAnswer) async throws -> InterventionSession {
        let tracks = audioRepository.getAvailableTracks()
        let trackId = tracks.randomElement()?.id ?? UUID()

        let session = InterventionSession(
            id: UUID(),
            appToken: appToken,
            questionAnswer: answer,
            audioTrackId: trackId,
            startedAt: Date(),
            completedAt: nil,
            result: .inProgress
        )

        try await sessionRepository.saveSession(session)
        return session
    }
}
