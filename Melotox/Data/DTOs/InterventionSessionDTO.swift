import Foundation

struct InterventionSessionDTO: Codable, Sendable {
    let id: UUID
    let appToken: String
    var questionAnswer: String
    let audioTrackId: UUID
    let startedAt: Date
    var completedAt: Date?
    var result: String

    func toEntity() -> InterventionSession {
        InterventionSession(
            id: id,
            appToken: appToken,
            questionAnswer: QuestionAnswer(rawValue: questionAnswer) ?? .no,
            audioTrackId: audioTrackId,
            startedAt: startedAt,
            completedAt: completedAt,
            result: SessionResult(rawValue: result) ?? .inProgress
        )
    }

    static func fromEntity(_ session: InterventionSession) -> InterventionSessionDTO {
        InterventionSessionDTO(
            id: session.id,
            appToken: session.appToken,
            questionAnswer: session.questionAnswer.rawValue,
            audioTrackId: session.audioTrackId,
            startedAt: session.startedAt,
            completedAt: session.completedAt,
            result: session.result.rawValue
        )
    }
}
