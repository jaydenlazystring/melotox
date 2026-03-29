import Foundation

struct InterventionSession: Identifiable, Codable, Sendable {
    let id: UUID
    let appToken: String
    var questionAnswer: QuestionAnswer
    let audioTrackId: UUID
    let startedAt: Date
    var completedAt: Date?
    var result: SessionResult
}
