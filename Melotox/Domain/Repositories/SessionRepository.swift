import Foundation

protocol SessionRepository: Sendable {
    func saveSession(_ session: InterventionSession) async throws
    func loadCurrentSession() async throws -> InterventionSession?
    func clearCurrentSession() async throws
}
