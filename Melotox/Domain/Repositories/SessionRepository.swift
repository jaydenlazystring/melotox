import Foundation

protocol SessionRepository: Sendable {
    func saveSession(_ session: InterventionSession) async throws
    func loadCurrentSession() async throws -> InterventionSession?
    func clearCurrentSession() async throws
    func recordActivity(_ record: ActivityRecord) async throws
    func loadActivityHistory() async throws -> [ActivityRecord]
}
