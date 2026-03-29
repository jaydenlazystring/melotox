import Foundation

protocol RestrictionRepository: Sendable {
    func saveProfile(_ profile: AppRestrictionProfile) async throws
    func loadProfile() async throws -> AppRestrictionProfile?
    func applyRestrictions(for tokens: [String]) async throws
    func removeRestrictions() async throws
}
