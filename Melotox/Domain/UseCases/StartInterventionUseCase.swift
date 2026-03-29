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
        guard let track = tracks.randomElement() else {
            throw MelotoxError.audioPlaybackFailed
        }

        let session = InterventionSession(
            id: UUID(),
            appToken: appToken,
            questionAnswer: answer,
            audioTrackId: track.id,
            startedAt: Date(),
            completedAt: nil,
            result: .inProgress
        )

        try await sessionRepository.saveSession(session)
        try await audioRepository.playTrack(track)

        return session
    }
}
