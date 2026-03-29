import Foundation

protocol UnlockRepository: Sendable {
    func grantUnlock(_ grant: UnlockGrant) async throws
    func getActiveGrant(for appToken: String) async throws -> UnlockGrant?
    func expireGrant(id: UUID) async throws
}
